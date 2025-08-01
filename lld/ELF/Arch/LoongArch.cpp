//===- LoongArch.cpp ------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "OutputSections.h"
#include "Symbols.h"
#include "SyntheticSections.h"
#include "Target.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/LEB128.h"

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

namespace {
class LoongArch final : public TargetInfo {
public:
  LoongArch(Ctx &);
  uint32_t calcEFlags() const override;
  int64_t getImplicitAddend(const uint8_t *buf, RelType type) const override;
  void writeGotPlt(uint8_t *buf, const Symbol &s) const override;
  void writeIgotPlt(uint8_t *buf, const Symbol &s) const override;
  void writePltHeader(uint8_t *buf) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;
  RelType getDynRel(RelType type) const override;
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  bool usesOnlyLowPageBits(RelType type) const override;
  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
  bool relaxOnce(int pass) const override;
  RelExpr adjustTlsExpr(RelType type, RelExpr expr) const override;
  void relocateAlloc(InputSectionBase &sec, uint8_t *buf) const override;
  void finalizeRelax(int passes) const override;

private:
  void tlsdescToIe(uint8_t *loc, const Relocation &rel, uint64_t val) const;
  void tlsdescToLe(uint8_t *loc, const Relocation &rel, uint64_t val) const;
};
} // end anonymous namespace

namespace {
enum Op {
  SUB_W = 0x00110000,
  SUB_D = 0x00118000,
  BREAK = 0x002a0000,
  SRLI_W = 0x00448000,
  SRLI_D = 0x00450000,
  ADDI_W = 0x02800000,
  ADDI_D = 0x02c00000,
  ANDI = 0x03400000,
  ORI = 0x03800000,
  LU12I_W = 0x14000000,
  PCADDI = 0x18000000,
  PCADDU12I = 0x1c000000,
  PCALAU12I = 0x1a000000,
  LD_W = 0x28800000,
  LD_D = 0x28c00000,
  JIRL = 0x4c000000,
  B = 0x50000000,
  BL = 0x54000000,
};

enum Reg {
  R_ZERO = 0,
  R_RA = 1,
  R_TP = 2,
  R_A0 = 4,
  R_T0 = 12,
  R_T1 = 13,
  R_T2 = 14,
  R_T3 = 15,
};
} // namespace

// Mask out the input's lowest 12 bits for use with `pcalau12i`, in sequences
// like `pcalau12i + addi.[wd]` or `pcalau12i + {ld,st}.*` where the `pcalau12i`
// produces a PC-relative intermediate value with the lowest 12 bits zeroed (the
// "page") for the next instruction to add in the "page offset". (`pcalau12i`
// stands for something like "PC ALigned Add Upper that starts from the 12th
// bit, Immediate".)
//
// Here a "page" is in fact just another way to refer to the 12-bit range
// allowed by the immediate field of the addi/ld/st instructions, and not
// related to the system or the kernel's actual page size. The semantics happen
// to match the AArch64 `adrp`, so the concept of "page" is borrowed here.
static uint64_t getLoongArchPage(uint64_t p) {
  return p & ~static_cast<uint64_t>(0xfff);
}

static uint32_t lo12(uint32_t val) { return val & 0xfff; }

// Calculate the adjusted page delta between dest and PC.
uint64_t elf::getLoongArchPageDelta(uint64_t dest, uint64_t pc, RelType type) {
  // Note that if the sequence being relocated is `pcalau12i + addi.d + lu32i.d
  // + lu52i.d`, they must be adjacent so that we can infer the PC of
  // `pcalau12i` when calculating the page delta for the other two instructions
  // (lu32i.d and lu52i.d). Compensate all the sign-extensions is a bit
  // complicated. Just use psABI recommended algorithm.
  uint64_t pcalau12i_pc;
  switch (type) {
  case R_LARCH_PCALA64_LO20:
  case R_LARCH_GOT64_PC_LO20:
  case R_LARCH_TLS_IE64_PC_LO20:
  case R_LARCH_TLS_DESC64_PC_LO20:
    pcalau12i_pc = pc - 8;
    break;
  case R_LARCH_PCALA64_HI12:
  case R_LARCH_GOT64_PC_HI12:
  case R_LARCH_TLS_IE64_PC_HI12:
  case R_LARCH_TLS_DESC64_PC_HI12:
    pcalau12i_pc = pc - 12;
    break;
  default:
    pcalau12i_pc = pc;
    break;
  }
  uint64_t result = getLoongArchPage(dest) - getLoongArchPage(pcalau12i_pc);
  if (dest & 0x800)
    result += 0x1000 - 0x1'0000'0000;
  if (result & 0x8000'0000)
    result += 0x1'0000'0000;
  return result;
}

static uint32_t hi20(uint32_t val) { return (val + 0x800) >> 12; }

static uint32_t insn(uint32_t op, uint32_t d, uint32_t j, uint32_t k) {
  return op | d | (j << 5) | (k << 10);
}

// Extract bits v[begin:end], where range is inclusive.
static uint32_t extractBits(uint64_t v, uint32_t begin, uint32_t end) {
  return begin == 63 ? v >> end : (v & ((1ULL << (begin + 1)) - 1)) >> end;
}

static uint32_t getD5(uint64_t v) { return extractBits(v, 4, 0); }

static uint32_t getJ5(uint64_t v) { return extractBits(v, 9, 5); }

static uint32_t setD5k16(uint32_t insn, uint32_t imm) {
  uint32_t immLo = extractBits(imm, 15, 0);
  uint32_t immHi = extractBits(imm, 20, 16);
  return (insn & 0xfc0003e0) | (immLo << 10) | immHi;
}

static uint32_t setD10k16(uint32_t insn, uint32_t imm) {
  uint32_t immLo = extractBits(imm, 15, 0);
  uint32_t immHi = extractBits(imm, 25, 16);
  return (insn & 0xfc000000) | (immLo << 10) | immHi;
}

static uint32_t setJ20(uint32_t insn, uint32_t imm) {
  return (insn & 0xfe00001f) | (extractBits(imm, 19, 0) << 5);
}

static uint32_t setJ5(uint32_t insn, uint32_t imm) {
  return (insn & 0xfffffc1f) | (extractBits(imm, 4, 0) << 5);
}

static uint32_t setK12(uint32_t insn, uint32_t imm) {
  return (insn & 0xffc003ff) | (extractBits(imm, 11, 0) << 10);
}

static uint32_t setK16(uint32_t insn, uint32_t imm) {
  return (insn & 0xfc0003ff) | (extractBits(imm, 15, 0) << 10);
}

static bool isJirl(uint32_t insn) {
  return (insn & 0xfc000000) == JIRL;
}

static void handleUleb128(Ctx &ctx, uint8_t *loc, uint64_t val) {
  const uint32_t maxcount = 1 + 64 / 7;
  uint32_t count;
  const char *error = nullptr;
  uint64_t orig = decodeULEB128(loc, &count, nullptr, &error);
  if (count > maxcount || (count == maxcount && error))
    Err(ctx) << getErrorLoc(ctx, loc) << "extra space for uleb128";
  uint64_t mask = count < maxcount ? (1ULL << 7 * count) - 1 : -1ULL;
  encodeULEB128((orig + val) & mask, loc, count);
}

LoongArch::LoongArch(Ctx &ctx) : TargetInfo(ctx) {
  // The LoongArch ISA itself does not have a limit on page sizes. According to
  // the ISA manual, the PS (page size) field in MTLB entries and CSR.STLBPS is
  // 6 bits wide, meaning the maximum page size is 2^63 which is equivalent to
  // "unlimited".
  // However, practically the maximum usable page size is constrained by the
  // kernel implementation, and 64KiB is the biggest non-huge page size
  // supported by Linux as of v6.4. The most widespread page size in use,
  // though, is 16KiB.
  defaultCommonPageSize = 16384;
  defaultMaxPageSize = 65536;
  write32le(trapInstr.data(), BREAK); // break 0

  copyRel = R_LARCH_COPY;
  pltRel = R_LARCH_JUMP_SLOT;
  relativeRel = R_LARCH_RELATIVE;
  iRelativeRel = R_LARCH_IRELATIVE;

  if (ctx.arg.is64) {
    symbolicRel = R_LARCH_64;
    tlsModuleIndexRel = R_LARCH_TLS_DTPMOD64;
    tlsOffsetRel = R_LARCH_TLS_DTPREL64;
    tlsGotRel = R_LARCH_TLS_TPREL64;
    tlsDescRel = R_LARCH_TLS_DESC64;
  } else {
    symbolicRel = R_LARCH_32;
    tlsModuleIndexRel = R_LARCH_TLS_DTPMOD32;
    tlsOffsetRel = R_LARCH_TLS_DTPREL32;
    tlsGotRel = R_LARCH_TLS_TPREL32;
    tlsDescRel = R_LARCH_TLS_DESC32;
  }

  gotRel = symbolicRel;

  // .got.plt[0] = _dl_runtime_resolve, .got.plt[1] = link_map
  gotPltHeaderEntriesNum = 2;

  pltHeaderSize = 32;
  pltEntrySize = 16;
  ipltEntrySize = 16;
}

static uint32_t getEFlags(Ctx &ctx, const InputFile *f) {
  if (ctx.arg.is64)
    return cast<ObjFile<ELF64LE>>(f)->getObj().getHeader().e_flags;
  return cast<ObjFile<ELF32LE>>(f)->getObj().getHeader().e_flags;
}

static bool inputFileHasCode(const InputFile *f) {
  for (const auto *sec : f->getSections())
    if (sec && sec->flags & SHF_EXECINSTR)
      return true;

  return false;
}

uint32_t LoongArch::calcEFlags() const {
  // If there are only binary input files (from -b binary), use a
  // value of 0 for the ELF header flags.
  if (ctx.objectFiles.empty())
    return 0;

  uint32_t target = 0;
  const InputFile *targetFile;
  for (const InputFile *f : ctx.objectFiles) {
    // Do not enforce ABI compatibility if the input file does not contain code.
    // This is useful for allowing linkage with data-only object files produced
    // with tools like objcopy, that have zero e_flags.
    if (!inputFileHasCode(f))
      continue;

    // Take the first non-zero e_flags as the reference.
    uint32_t flags = getEFlags(ctx, f);
    if (target == 0 && flags != 0) {
      target = flags;
      targetFile = f;
    }

    if ((flags & EF_LOONGARCH_ABI_MODIFIER_MASK) !=
        (target & EF_LOONGARCH_ABI_MODIFIER_MASK))
      ErrAlways(ctx) << f
                     << ": cannot link object files with different ABI from "
                     << targetFile;

    // We cannot process psABI v1.x / object ABI v0 files (containing stack
    // relocations), unlike ld.bfd.
    //
    // Instead of blindly accepting every v0 object and only failing at
    // relocation processing time, just disallow interlink altogether. We
    // don't expect significant usage of object ABI v0 in the wild (the old
    // world may continue using object ABI v0 for a while, but as it's not
    // binary-compatible with the upstream i.e. new-world ecosystem, it's not
    // being considered here).
    //
    // There are briefly some new-world systems with object ABI v0 binaries too.
    // It is because these systems were built before the new ABI was finalized.
    // These are not supported either due to the extremely small number of them,
    // and the few impacted users are advised to simply rebuild world or
    // reinstall a recent system.
    if ((flags & EF_LOONGARCH_OBJABI_MASK) != EF_LOONGARCH_OBJABI_V1)
      ErrAlways(ctx) << f << ": unsupported object file ABI version";
  }

  return target;
}

int64_t LoongArch::getImplicitAddend(const uint8_t *buf, RelType type) const {
  switch (type) {
  default:
    InternalErr(ctx, buf) << "cannot read addend for relocation " << type;
    return 0;
  case R_LARCH_32:
  case R_LARCH_TLS_DTPMOD32:
  case R_LARCH_TLS_DTPREL32:
  case R_LARCH_TLS_TPREL32:
    return SignExtend64<32>(read32le(buf));
  case R_LARCH_64:
  case R_LARCH_TLS_DTPMOD64:
  case R_LARCH_TLS_DTPREL64:
  case R_LARCH_TLS_TPREL64:
    return read64le(buf);
  case R_LARCH_RELATIVE:
  case R_LARCH_IRELATIVE:
    return ctx.arg.is64 ? read64le(buf) : read32le(buf);
  case R_LARCH_NONE:
  case R_LARCH_JUMP_SLOT:
    // These relocations are defined as not having an implicit addend.
    return 0;
  case R_LARCH_TLS_DESC32:
    return read32le(buf + 4);
  case R_LARCH_TLS_DESC64:
    return read64le(buf + 8);
  }
}

void LoongArch::writeGotPlt(uint8_t *buf, const Symbol &s) const {
  if (ctx.arg.is64)
    write64le(buf, ctx.in.plt->getVA());
  else
    write32le(buf, ctx.in.plt->getVA());
}

void LoongArch::writeIgotPlt(uint8_t *buf, const Symbol &s) const {
  if (ctx.arg.writeAddends) {
    if (ctx.arg.is64)
      write64le(buf, s.getVA(ctx));
    else
      write32le(buf, s.getVA(ctx));
  }
}

void LoongArch::writePltHeader(uint8_t *buf) const {
  // The LoongArch PLT is currently structured just like that of RISCV.
  // Annoyingly, this means the PLT is still using `pcaddu12i` to perform
  // PC-relative addressing (because `pcaddu12i` is the same as RISCV `auipc`),
  // in contrast to the AArch64-like page-offset scheme with `pcalau12i` that
  // is used everywhere else involving PC-relative operations in the LoongArch
  // ELF psABI v2.00.
  //
  // The `pcrel_{hi20,lo12}` operators are illustrative only and not really
  // supported by LoongArch assemblers.
  //
  //   pcaddu12i $t2, %pcrel_hi20(.got.plt)
  //   sub.[wd]  $t1, $t1, $t3
  //   ld.[wd]   $t3, $t2, %pcrel_lo12(.got.plt)  ; t3 = _dl_runtime_resolve
  //   addi.[wd] $t1, $t1, -pltHeaderSize-12      ; t1 = &.plt[i] - &.plt[0]
  //   addi.[wd] $t0, $t2, %pcrel_lo12(.got.plt)
  //   srli.[wd] $t1, $t1, (is64?1:2)             ; t1 = &.got.plt[i] - &.got.plt[0]
  //   ld.[wd]   $t0, $t0, Wordsize               ; t0 = link_map
  //   jr        $t3
  uint32_t offset = ctx.in.gotPlt->getVA() - ctx.in.plt->getVA();
  uint32_t sub = ctx.arg.is64 ? SUB_D : SUB_W;
  uint32_t ld = ctx.arg.is64 ? LD_D : LD_W;
  uint32_t addi = ctx.arg.is64 ? ADDI_D : ADDI_W;
  uint32_t srli = ctx.arg.is64 ? SRLI_D : SRLI_W;
  write32le(buf + 0, insn(PCADDU12I, R_T2, hi20(offset), 0));
  write32le(buf + 4, insn(sub, R_T1, R_T1, R_T3));
  write32le(buf + 8, insn(ld, R_T3, R_T2, lo12(offset)));
  write32le(buf + 12,
            insn(addi, R_T1, R_T1, lo12(-ctx.target->pltHeaderSize - 12)));
  write32le(buf + 16, insn(addi, R_T0, R_T2, lo12(offset)));
  write32le(buf + 20, insn(srli, R_T1, R_T1, ctx.arg.is64 ? 1 : 2));
  write32le(buf + 24, insn(ld, R_T0, R_T0, ctx.arg.wordsize));
  write32le(buf + 28, insn(JIRL, R_ZERO, R_T3, 0));
}

void LoongArch::writePlt(uint8_t *buf, const Symbol &sym,
                     uint64_t pltEntryAddr) const {
  // See the comment in writePltHeader for reason why pcaddu12i is used instead
  // of the pcalau12i that's more commonly seen in the ELF psABI v2.0 days.
  //
  //   pcaddu12i $t3, %pcrel_hi20(f@.got.plt)
  //   ld.[wd]   $t3, $t3, %pcrel_lo12(f@.got.plt)
  //   jirl      $t1, $t3, 0
  //   nop
  uint32_t offset = sym.getGotPltVA(ctx) - pltEntryAddr;
  write32le(buf + 0, insn(PCADDU12I, R_T3, hi20(offset), 0));
  write32le(buf + 4,
            insn(ctx.arg.is64 ? LD_D : LD_W, R_T3, R_T3, lo12(offset)));
  write32le(buf + 8, insn(JIRL, R_T1, R_T3, 0));
  write32le(buf + 12, insn(ANDI, R_ZERO, R_ZERO, 0));
}

RelType LoongArch::getDynRel(RelType type) const {
  return type == ctx.target->symbolicRel ? type
                                         : static_cast<RelType>(R_LARCH_NONE);
}

RelExpr LoongArch::getRelExpr(const RelType type, const Symbol &s,
                              const uint8_t *loc) const {
  switch (type) {
  case R_LARCH_NONE:
  case R_LARCH_MARK_LA:
  case R_LARCH_MARK_PCREL:
    return R_NONE;
  case R_LARCH_32:
  case R_LARCH_64:
  case R_LARCH_ABS_HI20:
  case R_LARCH_ABS_LO12:
  case R_LARCH_ABS64_LO20:
  case R_LARCH_ABS64_HI12:
    return R_ABS;
  case R_LARCH_PCALA_LO12:
    // We could just R_ABS, but the JIRL instruction reuses the relocation type
    // for a different purpose. The questionable usage is part of glibc 2.37
    // libc_nonshared.a [1], which is linked into user programs, so we have to
    // work around it for a while, even if a new relocation type may be
    // introduced in the future [2].
    //
    // [1]: https://sourceware.org/git/?p=glibc.git;a=commitdiff;h=9f482b73f41a9a1bbfb173aad0733d1c824c788a
    // [2]: https://github.com/loongson/la-abi-specs/pull/3
    return isJirl(read32le(loc)) ? R_PLT : R_ABS;
  case R_LARCH_TLS_DTPREL32:
  case R_LARCH_TLS_DTPREL64:
    return R_DTPREL;
  case R_LARCH_TLS_TPREL32:
  case R_LARCH_TLS_TPREL64:
  case R_LARCH_TLS_LE_HI20:
  case R_LARCH_TLS_LE_HI20_R:
  case R_LARCH_TLS_LE_LO12:
  case R_LARCH_TLS_LE_LO12_R:
  case R_LARCH_TLS_LE64_LO20:
  case R_LARCH_TLS_LE64_HI12:
    return R_TPREL;
  case R_LARCH_ADD6:
  case R_LARCH_ADD8:
  case R_LARCH_ADD16:
  case R_LARCH_ADD32:
  case R_LARCH_ADD64:
  case R_LARCH_ADD_ULEB128:
  case R_LARCH_SUB6:
  case R_LARCH_SUB8:
  case R_LARCH_SUB16:
  case R_LARCH_SUB32:
  case R_LARCH_SUB64:
  case R_LARCH_SUB_ULEB128:
    // The LoongArch add/sub relocs behave like the RISCV counterparts; reuse
    // the RelExpr to avoid code duplication.
    return RE_RISCV_ADD;
  case R_LARCH_32_PCREL:
  case R_LARCH_64_PCREL:
  case R_LARCH_PCREL20_S2:
    return R_PC;
  case R_LARCH_B16:
  case R_LARCH_B21:
  case R_LARCH_B26:
  case R_LARCH_CALL36:
    return R_PLT_PC;
  case R_LARCH_GOT_PC_HI20:
  case R_LARCH_GOT64_PC_LO20:
  case R_LARCH_GOT64_PC_HI12:
  case R_LARCH_TLS_IE_PC_HI20:
  case R_LARCH_TLS_IE64_PC_LO20:
  case R_LARCH_TLS_IE64_PC_HI12:
    return RE_LOONGARCH_GOT_PAGE_PC;
  case R_LARCH_GOT_PC_LO12:
  case R_LARCH_TLS_IE_PC_LO12:
    return RE_LOONGARCH_GOT;
  case R_LARCH_TLS_LD_PC_HI20:
  case R_LARCH_TLS_GD_PC_HI20:
    return RE_LOONGARCH_TLSGD_PAGE_PC;
  case R_LARCH_PCALA_HI20:
    // Why not RE_LOONGARCH_PAGE_PC, majority of references don't go through
    // PLT anyway so why waste time checking only to get everything relaxed back
    // to it?
    //
    // This is again due to the R_LARCH_PCALA_LO12 on JIRL case, where we want
    // both the HI20 and LO12 to potentially refer to the PLT. But in reality
    // the HI20 reloc appears earlier, and the relocs don't contain enough
    // information to let us properly resolve semantics per symbol.
    // Unlike RISCV, our LO12 relocs *do not* point to their corresponding HI20
    // relocs, hence it is nearly impossible to 100% accurately determine each
    // HI20's "flavor" without taking big performance hits, in the presence of
    // edge cases (e.g. HI20 without pairing LO12; paired LO12 placed so far
    // apart that relationship is not certain anymore), and programmer mistakes
    // (e.g. as outlined in https://github.com/loongson/la-abi-specs/pull/3).
    //
    // Ideally we would scan in an extra pass for all LO12s on JIRL, then mark
    // every HI20 reloc referring to the same symbol differently; this is not
    // feasible with the current function signature of getRelExpr that doesn't
    // allow for such inter-pass state.
    //
    // So, unfortunately we have to again workaround this quirk the same way as
    // BFD: assuming every R_LARCH_PCALA_HI20 is potentially PLT-needing, only
    // relaxing back to RE_LOONGARCH_PAGE_PC if it's known not so at a later
    // stage.
    return RE_LOONGARCH_PLT_PAGE_PC;
  case R_LARCH_PCALA64_LO20:
  case R_LARCH_PCALA64_HI12:
    return RE_LOONGARCH_PAGE_PC;
  case R_LARCH_GOT_HI20:
  case R_LARCH_GOT_LO12:
  case R_LARCH_GOT64_LO20:
  case R_LARCH_GOT64_HI12:
  case R_LARCH_TLS_IE_HI20:
  case R_LARCH_TLS_IE_LO12:
  case R_LARCH_TLS_IE64_LO20:
  case R_LARCH_TLS_IE64_HI12:
    return R_GOT;
  case R_LARCH_TLS_LD_HI20:
    return R_TLSLD_GOT;
  case R_LARCH_TLS_GD_HI20:
    return R_TLSGD_GOT;
  case R_LARCH_TLS_LE_ADD_R:
  case R_LARCH_RELAX:
    return ctx.arg.relax ? R_RELAX_HINT : R_NONE;
  case R_LARCH_ALIGN:
    return R_RELAX_HINT;
  case R_LARCH_TLS_DESC_PC_HI20:
  case R_LARCH_TLS_DESC64_PC_LO20:
  case R_LARCH_TLS_DESC64_PC_HI12:
    return RE_LOONGARCH_TLSDESC_PAGE_PC;
  case R_LARCH_TLS_DESC_PC_LO12:
  case R_LARCH_TLS_DESC_LD:
  case R_LARCH_TLS_DESC_HI20:
  case R_LARCH_TLS_DESC_LO12:
  case R_LARCH_TLS_DESC64_LO20:
  case R_LARCH_TLS_DESC64_HI12:
    return R_TLSDESC;
  case R_LARCH_TLS_DESC_CALL:
    return R_TLSDESC_CALL;
  case R_LARCH_TLS_LD_PCREL20_S2:
    return R_TLSLD_PC;
  case R_LARCH_TLS_GD_PCREL20_S2:
    return R_TLSGD_PC;
  case R_LARCH_TLS_DESC_PCREL20_S2:
    return R_TLSDESC_PC;

  // Other known relocs that are explicitly unimplemented:
  //
  // - psABI v1 relocs that need a stateful stack machine to work, and not
  //   required when implementing psABI v2;
  // - relocs that are not used anywhere (R_LARCH_{ADD,SUB}_24 [1], and the
  //   two GNU vtable-related relocs).
  //
  // [1]: https://web.archive.org/web/20230709064026/https://github.com/loongson/LoongArch-Documentation/issues/51
  default:
    Err(ctx) << getErrorLoc(ctx, loc) << "unknown relocation (" << type.v
             << ") against symbol " << &s;
    return R_NONE;
  }
}

bool LoongArch::usesOnlyLowPageBits(RelType type) const {
  switch (type) {
  default:
    return false;
  case R_LARCH_PCALA_LO12:
  case R_LARCH_GOT_LO12:
  case R_LARCH_GOT_PC_LO12:
  case R_LARCH_TLS_IE_PC_LO12:
  case R_LARCH_TLS_DESC_LO12:
  case R_LARCH_TLS_DESC_PC_LO12:
    return true;
  }
}

void LoongArch::relocate(uint8_t *loc, const Relocation &rel,
                         uint64_t val) const {
  switch (rel.type) {
  case R_LARCH_32_PCREL:
    checkInt(ctx, loc, val, 32, rel);
    [[fallthrough]];
  case R_LARCH_32:
  case R_LARCH_TLS_DTPREL32:
    write32le(loc, val);
    return;
  case R_LARCH_64:
  case R_LARCH_TLS_DTPREL64:
  case R_LARCH_64_PCREL:
    write64le(loc, val);
    return;

  // Relocs intended for `pcaddi`.
  case R_LARCH_PCREL20_S2:
  case R_LARCH_TLS_LD_PCREL20_S2:
  case R_LARCH_TLS_GD_PCREL20_S2:
  case R_LARCH_TLS_DESC_PCREL20_S2:
    checkInt(ctx, loc, val, 22, rel);
    checkAlignment(ctx, loc, val, 4, rel);
    write32le(loc, setJ20(read32le(loc), val >> 2));
    return;

  case R_LARCH_B16:
    checkInt(ctx, loc, val, 18, rel);
    checkAlignment(ctx, loc, val, 4, rel);
    write32le(loc, setK16(read32le(loc), val >> 2));
    return;

  case R_LARCH_B21:
    checkInt(ctx, loc, val, 23, rel);
    checkAlignment(ctx, loc, val, 4, rel);
    write32le(loc, setD5k16(read32le(loc), val >> 2));
    return;

  case R_LARCH_B26:
    checkInt(ctx, loc, val, 28, rel);
    checkAlignment(ctx, loc, val, 4, rel);
    write32le(loc, setD10k16(read32le(loc), val >> 2));
    return;

  case R_LARCH_CALL36: {
    // This relocation is designed for adjacent pcaddu18i+jirl pairs that
    // are patched in one time. Because of sign extension of these insns'
    // immediate fields, the relocation range is [-128G - 0x20000, +128G -
    // 0x20000) (of course must be 4-byte aligned).
    if (((int64_t)val + 0x20000) != llvm::SignExtend64(val + 0x20000, 38))
      reportRangeError(ctx, loc, rel, Twine(val), llvm::minIntN(38) - 0x20000,
                       llvm::maxIntN(38) - 0x20000);
    checkAlignment(ctx, loc, val, 4, rel);
    // Since jirl performs sign extension on the offset immediate, adds (1<<17)
    // to original val to get the correct hi20.
    uint32_t hi20 = extractBits(val + (1 << 17), 37, 18);
    // Despite the name, the lower part is actually 18 bits with 4-byte aligned.
    uint32_t lo16 = extractBits(val, 17, 2);
    write32le(loc, setJ20(read32le(loc), hi20));
    write32le(loc + 4, setK16(read32le(loc + 4), lo16));
    return;
  }

  // Relocs intended for `addi`, `ld` or `st`.
  case R_LARCH_PCALA_LO12:
    // We have to again inspect the insn word to handle the R_LARCH_PCALA_LO12
    // on JIRL case: firstly JIRL wants its immediate's 2 lowest zeroes
    // removed by us (in contrast to regular R_LARCH_PCALA_LO12), secondly
    // its immediate slot width is different too (16, not 12).
    // In this case, process like an R_LARCH_B16, but without overflow checking
    // and only taking the value's lowest 12 bits.
    if (isJirl(read32le(loc))) {
      checkAlignment(ctx, loc, val, 4, rel);
      val = SignExtend64<12>(val);
      write32le(loc, setK16(read32le(loc), val >> 2));
      return;
    }
    [[fallthrough]];
  case R_LARCH_ABS_LO12:
  case R_LARCH_GOT_PC_LO12:
  case R_LARCH_GOT_LO12:
  case R_LARCH_TLS_LE_LO12:
  case R_LARCH_TLS_IE_PC_LO12:
  case R_LARCH_TLS_IE_LO12:
  case R_LARCH_TLS_LE_LO12_R:
  case R_LARCH_TLS_DESC_PC_LO12:
  case R_LARCH_TLS_DESC_LO12:
    write32le(loc, setK12(read32le(loc), extractBits(val, 11, 0)));
    return;

  // Relocs intended for `lu12i.w` or `pcalau12i`.
  case R_LARCH_ABS_HI20:
  case R_LARCH_PCALA_HI20:
  case R_LARCH_GOT_PC_HI20:
  case R_LARCH_GOT_HI20:
  case R_LARCH_TLS_LE_HI20:
  case R_LARCH_TLS_IE_PC_HI20:
  case R_LARCH_TLS_IE_HI20:
  case R_LARCH_TLS_LD_PC_HI20:
  case R_LARCH_TLS_LD_HI20:
  case R_LARCH_TLS_GD_PC_HI20:
  case R_LARCH_TLS_GD_HI20:
  case R_LARCH_TLS_DESC_PC_HI20:
  case R_LARCH_TLS_DESC_HI20:
    write32le(loc, setJ20(read32le(loc), extractBits(val, 31, 12)));
    return;
  case R_LARCH_TLS_LE_HI20_R:
    write32le(loc, setJ20(read32le(loc), extractBits(val + 0x800, 31, 12)));
    return;

  // Relocs intended for `lu32i.d`.
  case R_LARCH_ABS64_LO20:
  case R_LARCH_PCALA64_LO20:
  case R_LARCH_GOT64_PC_LO20:
  case R_LARCH_GOT64_LO20:
  case R_LARCH_TLS_LE64_LO20:
  case R_LARCH_TLS_IE64_PC_LO20:
  case R_LARCH_TLS_IE64_LO20:
  case R_LARCH_TLS_DESC64_PC_LO20:
  case R_LARCH_TLS_DESC64_LO20:
    write32le(loc, setJ20(read32le(loc), extractBits(val, 51, 32)));
    return;

  // Relocs intended for `lu52i.d`.
  case R_LARCH_ABS64_HI12:
  case R_LARCH_PCALA64_HI12:
  case R_LARCH_GOT64_PC_HI12:
  case R_LARCH_GOT64_HI12:
  case R_LARCH_TLS_LE64_HI12:
  case R_LARCH_TLS_IE64_PC_HI12:
  case R_LARCH_TLS_IE64_HI12:
  case R_LARCH_TLS_DESC64_PC_HI12:
  case R_LARCH_TLS_DESC64_HI12:
    write32le(loc, setK12(read32le(loc), extractBits(val, 63, 52)));
    return;

  case R_LARCH_ADD6:
    *loc = (*loc & 0xc0) | ((*loc + val) & 0x3f);
    return;
  case R_LARCH_ADD8:
    *loc += val;
    return;
  case R_LARCH_ADD16:
    write16le(loc, read16le(loc) + val);
    return;
  case R_LARCH_ADD32:
    write32le(loc, read32le(loc) + val);
    return;
  case R_LARCH_ADD64:
    write64le(loc, read64le(loc) + val);
    return;
  case R_LARCH_ADD_ULEB128:
    handleUleb128(ctx, loc, val);
    return;
  case R_LARCH_SUB6:
    *loc = (*loc & 0xc0) | ((*loc - val) & 0x3f);
    return;
  case R_LARCH_SUB8:
    *loc -= val;
    return;
  case R_LARCH_SUB16:
    write16le(loc, read16le(loc) - val);
    return;
  case R_LARCH_SUB32:
    write32le(loc, read32le(loc) - val);
    return;
  case R_LARCH_SUB64:
    write64le(loc, read64le(loc) - val);
    return;
  case R_LARCH_SUB_ULEB128:
    handleUleb128(ctx, loc, -val);
    return;

  case R_LARCH_MARK_LA:
  case R_LARCH_MARK_PCREL:
    // no-op
    return;

  case R_LARCH_TLS_LE_ADD_R:
  case R_LARCH_RELAX:
    return; // Ignored (for now)

  case R_LARCH_TLS_DESC_LD:
    return; // nothing to do.
  case R_LARCH_TLS_DESC32:
    write32le(loc + 4, val);
    return;
  case R_LARCH_TLS_DESC64:
    write64le(loc + 8, val);
    return;

  default:
    llvm_unreachable("unknown relocation");
  }
}

static bool relaxable(ArrayRef<Relocation> relocs, size_t i) {
  return i + 1 < relocs.size() && relocs[i + 1].type == R_LARCH_RELAX;
}

static bool isPairRelaxable(ArrayRef<Relocation> relocs, size_t i) {
  return relaxable(relocs, i) && relaxable(relocs, i + 2) &&
         relocs[i].offset + 4 == relocs[i + 2].offset;
}

// Relax code sequence.
// From:
//   pcalau12i     $a0, %pc_hi20(sym) | %ld_pc_hi20(sym)  | %gd_pc_hi20(sym)
//                    | %desc_pc_hi20(sym)
//   addi.w/d $a0, $a0, %pc_lo12(sym) | %got_pc_lo12(sym) | %got_pc_lo12(sym)
//                    | %desc_pc_lo12(sym)
// To:
//   pcaddi        $a0, %pc_lo12(sym) | %got_pc_lo12(sym) | %got_pc_lo12(sym)
//                    | %desc_pcrel_20(sym)
//
// From:
//   pcalau12i $a0, %got_pc_hi20(sym_got)
//   ld.w/d $a0, $a0, %got_pc_lo12(sym_got)
// To:
//   pcaddi $a0, %got_pc_hi20(sym_got)
static void relaxPCHi20Lo12(Ctx &ctx, const InputSection &sec, size_t i,
                            uint64_t loc, Relocation &rHi20, Relocation &rLo12,
                            uint32_t &remove) {
  // check if the relocations are relaxable sequences.
  if (!((rHi20.type == R_LARCH_PCALA_HI20 &&
         rLo12.type == R_LARCH_PCALA_LO12) ||
        (rHi20.type == R_LARCH_GOT_PC_HI20 &&
         rLo12.type == R_LARCH_GOT_PC_LO12) ||
        (rHi20.type == R_LARCH_TLS_GD_PC_HI20 &&
         rLo12.type == R_LARCH_GOT_PC_LO12) ||
        (rHi20.type == R_LARCH_TLS_LD_PC_HI20 &&
         rLo12.type == R_LARCH_GOT_PC_LO12) ||
        (rHi20.type == R_LARCH_TLS_DESC_PC_HI20 &&
         rLo12.type == R_LARCH_TLS_DESC_PC_LO12)))
    return;

  // GOT references to absolute symbols can't be relaxed to use pcaddi in
  // position-independent code, because these instructions produce a relative
  // address.
  // Meanwhile skip undefined, preemptible and STT_GNU_IFUNC symbols, because
  // these symbols may be resolve in runtime.
  if (rHi20.type == R_LARCH_GOT_PC_HI20 &&
      (!rHi20.sym->isDefined() || rHi20.sym->isPreemptible ||
       rHi20.sym->isGnuIFunc() ||
       (ctx.arg.isPic && !cast<Defined>(*rHi20.sym).section)))
    return;

  uint64_t dest = 0;
  if (rHi20.expr == RE_LOONGARCH_PLT_PAGE_PC)
    dest = rHi20.sym->getPltVA(ctx);
  else if (rHi20.expr == RE_LOONGARCH_PAGE_PC ||
           rHi20.expr == RE_LOONGARCH_GOT_PAGE_PC)
    dest = rHi20.sym->getVA(ctx);
  else if (rHi20.expr == RE_LOONGARCH_TLSGD_PAGE_PC)
    dest = ctx.in.got->getGlobalDynAddr(*rHi20.sym);
  else if (rHi20.expr == RE_LOONGARCH_TLSDESC_PAGE_PC)
    dest = ctx.in.got->getTlsDescAddr(*rHi20.sym);
  else {
    Err(ctx) << getErrorLoc(ctx, (const uint8_t *)loc) << "unknown expr ("
             << rHi20.expr << ") against symbol " << rHi20.sym
             << "in relaxPCHi20Lo12";
    return;
  }
  dest += rHi20.addend;

  const int64_t displace = dest - loc;
  // Check if the displace aligns 4 bytes or exceeds the range of pcaddi.
  if ((displace & 0x3) != 0 || !isInt<22>(displace))
    return;

  // Note: If we can ensure that the .o files generated by LLVM only contain
  // relaxable instruction sequences with R_LARCH_RELAX, then we do not need to
  // decode instructions. The relaxable instruction sequences imply the
  // following constraints:
  // * For relocation pairs related to got_pc, the opcodes of instructions
  // must be pcalau12i + ld.w/d. In other cases, the opcodes must be pcalau12i +
  // addi.w/d.
  // * The destination register of pcalau12i is guaranteed to be used only by
  // the immediately following instruction.
  const uint32_t currInsn = read32le(sec.content().data() + rHi20.offset);
  const uint32_t nextInsn = read32le(sec.content().data() + rLo12.offset);
  // Check if use the same register.
  if (getD5(currInsn) != getJ5(nextInsn) || getJ5(nextInsn) != getD5(nextInsn))
    return;

  sec.relaxAux->relocTypes[i] = R_LARCH_RELAX;
  if (rHi20.type == R_LARCH_TLS_GD_PC_HI20)
    sec.relaxAux->relocTypes[i + 2] = R_LARCH_TLS_GD_PCREL20_S2;
  else if (rHi20.type == R_LARCH_TLS_LD_PC_HI20)
    sec.relaxAux->relocTypes[i + 2] = R_LARCH_TLS_LD_PCREL20_S2;
  else if (rHi20.type == R_LARCH_TLS_DESC_PC_HI20)
    sec.relaxAux->relocTypes[i + 2] = R_LARCH_TLS_DESC_PCREL20_S2;
  else
    sec.relaxAux->relocTypes[i + 2] = R_LARCH_PCREL20_S2;
  sec.relaxAux->writes.push_back(insn(PCADDI, getD5(nextInsn), 0, 0));
  remove = 4;
}

// Relax code sequence.
// From:
//   pcaddu18i $ra, %call36(foo)
//   jirl $ra, $ra, 0
// To:
//   b/bl foo
static void relaxCall36(Ctx &ctx, const InputSection &sec, size_t i,
                        uint64_t loc, Relocation &r, uint32_t &remove) {
  const uint64_t dest =
      (r.expr == R_PLT_PC ? r.sym->getPltVA(ctx) : r.sym->getVA(ctx)) +
      r.addend;

  const int64_t displace = dest - loc;
  // Check if the displace aligns 4 bytes or exceeds the range of b[l].
  if ((displace & 0x3) != 0 || !isInt<28>(displace))
    return;

  const uint32_t nextInsn = read32le(sec.content().data() + r.offset + 4);
  if (getD5(nextInsn) == R_RA) {
    // convert jirl to bl
    sec.relaxAux->relocTypes[i] = R_LARCH_B26;
    sec.relaxAux->writes.push_back(insn(BL, 0, 0, 0));
    remove = 4;
  } else if (getD5(nextInsn) == R_ZERO) {
    // convert jirl to b
    sec.relaxAux->relocTypes[i] = R_LARCH_B26;
    sec.relaxAux->writes.push_back(insn(B, 0, 0, 0));
    remove = 4;
  }
}

// Relax code sequence.
// From:
//   lu12i.w $rd, %le_hi20_r(sym)
//   add.w/d $rd, $rd, $tp, %le_add_r(sym)
//   addi/ld/st.w/d $rd, $rd, %le_lo12_r(sym)
// To:
//   addi/ld/st.w/d $rd, $tp, %le_lo12_r(sym)
static void relaxTlsLe(Ctx &ctx, const InputSection &sec, size_t i,
                       uint64_t loc, Relocation &r, uint32_t &remove) {
  uint64_t val = r.sym->getVA(ctx, r.addend);
  // Check if the val exceeds the range of addi/ld/st.
  if (!isInt<12>(val))
    return;
  uint32_t currInsn = read32le(sec.content().data() + r.offset);
  switch (r.type) {
  case R_LARCH_TLS_LE_HI20_R:
  case R_LARCH_TLS_LE_ADD_R:
    sec.relaxAux->relocTypes[i] = R_LARCH_RELAX;
    remove = 4;
    break;
  case R_LARCH_TLS_LE_LO12_R:
    sec.relaxAux->writes.push_back(setJ5(currInsn, R_TP));
    sec.relaxAux->relocTypes[i] = R_LARCH_TLS_LE_LO12_R;
    break;
  }
}

static bool relax(Ctx &ctx, InputSection &sec) {
  const uint64_t secAddr = sec.getVA();
  const MutableArrayRef<Relocation> relocs = sec.relocs();
  auto &aux = *sec.relaxAux;
  bool changed = false;
  ArrayRef<SymbolAnchor> sa = ArrayRef(aux.anchors);
  uint64_t delta = 0;

  std::fill_n(aux.relocTypes.get(), relocs.size(), R_LARCH_NONE);
  aux.writes.clear();
  for (auto [i, r] : llvm::enumerate(relocs)) {
    const uint64_t loc = secAddr + r.offset - delta;
    uint32_t &cur = aux.relocDeltas[i], remove = 0;
    switch (r.type) {
    case R_LARCH_ALIGN: {
      const uint64_t addend =
          r.sym->isUndefined() ? Log2_64(r.addend) + 1 : r.addend;
      const uint64_t allBytes = (1ULL << (addend & 0xff)) - 4;
      const uint64_t align = 1ULL << (addend & 0xff);
      const uint64_t maxBytes = addend >> 8;
      const uint64_t off = loc & (align - 1);
      const uint64_t curBytes = off == 0 ? 0 : align - off;
      // All bytes beyond the alignment boundary should be removed.
      // If emit bytes more than max bytes to emit, remove all.
      if (maxBytes != 0 && curBytes > maxBytes)
        remove = allBytes;
      else
        remove = allBytes - curBytes;
      // If we can't satisfy this alignment, we've found a bad input.
      if (LLVM_UNLIKELY(static_cast<int32_t>(remove) < 0)) {
        Err(ctx) << getErrorLoc(ctx, (const uint8_t *)loc)
                 << "insufficient padding bytes for " << r.type << ": "
                 << allBytes << " bytes available for "
                 << "requested alignment of " << align << " bytes";
        remove = 0;
      }
      break;
    }
    case R_LARCH_PCALA_HI20:
    case R_LARCH_GOT_PC_HI20:
    case R_LARCH_TLS_GD_PC_HI20:
    case R_LARCH_TLS_LD_PC_HI20:
      // The overflow check for i+2 will be carried out in isPairRelaxable.
      if (isPairRelaxable(relocs, i))
        relaxPCHi20Lo12(ctx, sec, i, loc, r, relocs[i + 2], remove);
      break;
    case R_LARCH_TLS_DESC_PC_HI20:
      if (r.expr == RE_LOONGARCH_RELAX_TLS_GD_TO_IE_PAGE_PC ||
          r.expr == R_RELAX_TLS_GD_TO_LE) {
        if (relaxable(relocs, i))
          remove = 4;
      } else if (isPairRelaxable(relocs, i))
        relaxPCHi20Lo12(ctx, sec, i, loc, r, relocs[i + 2], remove);
      break;
    case R_LARCH_CALL36:
      if (relaxable(relocs, i))
        relaxCall36(ctx, sec, i, loc, r, remove);
      break;
    case R_LARCH_TLS_LE_HI20_R:
    case R_LARCH_TLS_LE_ADD_R:
    case R_LARCH_TLS_LE_LO12_R:
      if (relaxable(relocs, i))
        relaxTlsLe(ctx, sec, i, loc, r, remove);
      break;
    case R_LARCH_TLS_IE_PC_HI20:
      if (relaxable(relocs, i) && r.expr == R_RELAX_TLS_IE_TO_LE &&
          isUInt<12>(r.sym->getVA(ctx, r.addend)))
        remove = 4;
      break;
    case R_LARCH_TLS_DESC_PC_LO12:
      if (relaxable(relocs, i) &&
          (r.expr == RE_LOONGARCH_RELAX_TLS_GD_TO_IE_PAGE_PC ||
           r.expr == R_RELAX_TLS_GD_TO_LE))
        remove = 4;
      break;
    case R_LARCH_TLS_DESC_LD:
      if (relaxable(relocs, i) && r.expr == R_RELAX_TLS_GD_TO_LE &&
          isUInt<12>(r.sym->getVA(ctx, r.addend)))
        remove = 4;
      break;
    }

    // For all anchors whose offsets are <= r.offset, they are preceded by
    // the previous relocation whose `relocDeltas` value equals `delta`.
    // Decrease their st_value and update their st_size.
    for (; sa.size() && sa[0].offset <= r.offset; sa = sa.slice(1)) {
      if (sa[0].end)
        sa[0].d->size = sa[0].offset - delta - sa[0].d->value;
      else
        sa[0].d->value = sa[0].offset - delta;
    }
    delta += remove;
    if (delta != cur) {
      cur = delta;
      changed = true;
    }
  }

  for (const SymbolAnchor &a : sa) {
    if (a.end)
      a.d->size = a.offset - delta - a.d->value;
    else
      a.d->value = a.offset - delta;
  }
  // Inform assignAddresses that the size has changed.
  if (!isUInt<32>(delta))
    Fatal(ctx) << "section size decrease is too large: " << delta;
  sec.bytesDropped = delta;
  return changed;
}

// Convert TLS IE to LE in the normal or medium code model.
// Original code sequence:
//  * pcalau12i $a0, %ie_pc_hi20(sym)
//  * ld.d      $a0, $a0, %ie_pc_lo12(sym)
//
// The code sequence converted is as follows:
//  * lu12i.w   $a0, %le_hi20(sym)      # le_hi20 != 0, otherwise NOP
//  * ori       $a0, src, %le_lo12(sym) # le_hi20 != 0, src = $a0,
//                                      # otherwise,    src = $zero
//
// When relaxation enables, redundant NOPs can be removed.
static void tlsIeToLe(uint8_t *loc, const Relocation &rel, uint64_t val) {
  assert(isInt<32>(val) &&
         "val exceeds the range of medium code model in tlsIeToLe");

  bool isUInt12 = isUInt<12>(val);
  const uint32_t currInsn = read32le(loc);
  switch (rel.type) {
  case R_LARCH_TLS_IE_PC_HI20:
    if (isUInt12)
      write32le(loc, insn(ANDI, R_ZERO, R_ZERO, 0)); // nop
    else
      write32le(loc, insn(LU12I_W, getD5(currInsn), extractBits(val, 31, 12),
                          0)); // lu12i.w $a0, %le_hi20
    break;
  case R_LARCH_TLS_IE_PC_LO12:
    if (isUInt12)
      write32le(loc, insn(ORI, getD5(currInsn), R_ZERO,
                          val)); // ori $a0, $zero, %le_lo12
    else
      write32le(loc, insn(ORI, getD5(currInsn), getJ5(currInsn),
                          lo12(val))); // ori $a0, $a0, %le_lo12
    break;
  }
}

// Convert TLSDESC GD/LD to IE.
// In normal or medium code model, there are two forms of code sequences:
//  * pcalau12i  $a0, %desc_pc_hi20(sym_desc)
//  * addi.d     $a0, $a0, %desc_pc_lo12(sym_desc)
//  * ld.d       $ra, $a0, %desc_ld(sym_desc)
//  * jirl       $ra, $ra, %desc_call(sym_desc)
//  ------
//  * pcaddi $a0, %desc_pcrel_20(a)
//  * load $ra, $a0, %desc_ld(a)
//  * jirl $ra, $ra, %desc_call(a)
//
// The code sequence obtained is as follows:
//  * pcalau12i $a0, %ie_pc_hi20(sym_ie)
//  * ld.[wd]   $a0, $a0, %ie_pc_lo12(sym_ie)
//
// Simplicity, whether tlsdescToIe or tlsdescToLe, we always tend to convert the
// preceding instructions to NOPs, due to both forms of code sequence
// (corresponding to relocation combinations:
// R_LARCH_TLS_DESC_PC_HI20+R_LARCH_TLS_DESC_PC_LO12 and
// R_LARCH_TLS_DESC_PCREL20_S2) have same process.
//
// When relaxation enables, redundant NOPs can be removed.
void LoongArch::tlsdescToIe(uint8_t *loc, const Relocation &rel,
                            uint64_t val) const {
  switch (rel.type) {
  case R_LARCH_TLS_DESC_PC_HI20:
  case R_LARCH_TLS_DESC_PC_LO12:
  case R_LARCH_TLS_DESC_PCREL20_S2:
    write32le(loc, insn(ANDI, R_ZERO, R_ZERO, 0)); // nop
    break;
  case R_LARCH_TLS_DESC_LD:
    write32le(loc, insn(PCALAU12I, R_A0, 0, 0)); // pcalau12i $a0, %ie_pc_hi20
    relocateNoSym(loc, R_LARCH_TLS_IE_PC_HI20, val);
    break;
  case R_LARCH_TLS_DESC_CALL:
    write32le(loc, insn(ctx.arg.is64 ? LD_D : LD_W, R_A0, R_A0,
                        0)); // ld.[wd] $a0, $a0, %ie_pc_lo12
    relocateNoSym(loc, R_LARCH_TLS_IE_PC_LO12, val);
    break;
  default:
    llvm_unreachable("unsupported relocation for TLSDESC to IE");
  }
}

// Convert TLSDESC GD/LD to LE.
// The code sequence obtained in the normal or medium code model is as follows:
//  * lu12i.w   $a0, %le_hi20(sym)      # le_hi20 != 0, otherwise NOP
//  * ori       $a0, src, %le_lo12(sym) # le_hi20 != 0, src = $a0,
//                                      # otherwise,    src = $zero
// See the comment in tlsdescToIe for detailed information.
void LoongArch::tlsdescToLe(uint8_t *loc, const Relocation &rel,
                            uint64_t val) const {
  assert(isInt<32>(val) &&
         "val exceeds the range of medium code model in tlsdescToLe");

  bool isUInt12 = isUInt<12>(val);
  switch (rel.type) {
  case R_LARCH_TLS_DESC_PC_HI20:
  case R_LARCH_TLS_DESC_PC_LO12:
  case R_LARCH_TLS_DESC_PCREL20_S2:
    write32le(loc, insn(ANDI, R_ZERO, R_ZERO, 0)); // nop
    break;
  case R_LARCH_TLS_DESC_LD:
    if (isUInt12)
      write32le(loc, insn(ANDI, R_ZERO, R_ZERO, 0)); // nop
    else
      write32le(loc, insn(LU12I_W, R_A0, extractBits(val, 31, 12),
                          0)); // lu12i.w $a0, %le_hi20
    break;
  case R_LARCH_TLS_DESC_CALL:
    if (isUInt12)
      write32le(loc, insn(ORI, R_A0, R_ZERO, val)); // ori $a0, $zero, %le_lo12
    else
      write32le(loc,
                insn(ORI, R_A0, R_A0, lo12(val))); // ori $a0, $a0, %le_lo12
    break;
  default:
    llvm_unreachable("unsupported relocation for TLSDESC to LE");
  }
}

// During TLSDESC GD_TO_IE, the converted code sequence always includes an
// instruction related to the Lo12 relocation (ld.[wd]). To obtain correct val
// in `getRelocTargetVA`, expr of this instruction should be adjusted to
// R_RELAX_TLS_GD_TO_IE_ABS, while expr of other instructions related to the
// Hi20 relocation (pcalau12i) should be adjusted to
// RE_LOONGARCH_RELAX_TLS_GD_TO_IE_PAGE_PC. Specifically, in the normal or
// medium code model, the instruction with relocation R_LARCH_TLS_DESC_CALL is
// the candidate of Lo12 relocation.
RelExpr LoongArch::adjustTlsExpr(RelType type, RelExpr expr) const {
  if (expr == R_RELAX_TLS_GD_TO_IE) {
    if (type != R_LARCH_TLS_DESC_CALL)
      return RE_LOONGARCH_RELAX_TLS_GD_TO_IE_PAGE_PC;
    return R_RELAX_TLS_GD_TO_IE_ABS;
  }
  return expr;
}

void LoongArch::relocateAlloc(InputSectionBase &sec, uint8_t *buf) const {
  const unsigned bits = ctx.arg.is64 ? 64 : 32;
  uint64_t secAddr = sec.getOutputSection()->addr;
  if (auto *s = dyn_cast<InputSection>(&sec))
    secAddr += s->outSecOff;
  else if (auto *ehIn = dyn_cast<EhInputSection>(&sec))
    secAddr += ehIn->getParent()->outSecOff;
  bool isExtreme = false, isRelax = false;
  const MutableArrayRef<Relocation> relocs = sec.relocs();
  for (size_t i = 0, size = relocs.size(); i != size; ++i) {
    Relocation &rel = relocs[i];
    uint8_t *loc = buf + rel.offset;
    uint64_t val = SignExtend64(
        sec.getRelocTargetVA(ctx, rel, secAddr + rel.offset), bits);

    switch (rel.expr) {
    case R_RELAX_HINT:
      continue;
    case R_RELAX_TLS_IE_TO_LE:
      if (rel.type == R_LARCH_TLS_IE_PC_HI20) {
        // LoongArch does not support IE to LE optimization in the extreme code
        // model. In this case, the relocs are as follows:
        //
        //  * i   -- R_LARCH_TLS_IE_PC_HI20
        //  * i+1 -- R_LARCH_TLS_IE_PC_LO12
        //  * i+2 -- R_LARCH_TLS_IE64_PC_LO20
        //  * i+3 -- R_LARCH_TLS_IE64_PC_HI12
        isExtreme =
            i + 2 < size && relocs[i + 2].type == R_LARCH_TLS_IE64_PC_LO20;
      }
      if (isExtreme) {
        rel.expr = getRelExpr(rel.type, *rel.sym, loc);
        val = SignExtend64(sec.getRelocTargetVA(ctx, rel, secAddr + rel.offset),
                           bits);
        relocateNoSym(loc, rel.type, val);
      } else {
        isRelax = relaxable(relocs, i);
        if (isRelax && rel.type == R_LARCH_TLS_IE_PC_HI20 && isUInt<12>(val))
          continue;
        tlsIeToLe(loc, rel, val);
      }
      continue;
    case RE_LOONGARCH_RELAX_TLS_GD_TO_IE_PAGE_PC:
      if (rel.type == R_LARCH_TLS_DESC_PC_HI20) {
        // LoongArch does not support TLSDESC GD/LD to LE/IE optimization in the
        // extreme code model. In these cases, the relocs are as follows:
        //
        //  * i   -- R_LARCH_TLS_DESC_PC_HI20
        //  * i+1 -- R_LARCH_TLS_DESC_PC_LO12
        //  * i+2 -- R_LARCH_TLS_DESC64_PC_LO20
        //  * i+3 -- R_LARCH_TLS_DESC64_PC_HI12
        isExtreme =
            i + 2 < size && relocs[i + 2].type == R_LARCH_TLS_DESC64_PC_LO20;
      }
      [[fallthrough]];
    case R_RELAX_TLS_GD_TO_IE_ABS:
      if (isExtreme) {
        if (rel.type == R_LARCH_TLS_DESC_CALL)
          continue;
        rel.expr = getRelExpr(rel.type, *rel.sym, loc);
        val = SignExtend64(sec.getRelocTargetVA(ctx, rel, secAddr + rel.offset),
                           bits);
        relocateNoSym(loc, rel.type, val);
      } else {
        isRelax = relaxable(relocs, i);
        if (isRelax && (rel.type == R_LARCH_TLS_DESC_PC_HI20 ||
                        rel.type == R_LARCH_TLS_DESC_PC_LO12))
          continue;
        tlsdescToIe(loc, rel, val);
      }
      continue;
    case R_RELAX_TLS_GD_TO_LE:
      if (rel.type == R_LARCH_TLS_DESC_PC_HI20) {
        isExtreme =
            i + 2 < size && relocs[i + 2].type == R_LARCH_TLS_DESC64_PC_LO20;
      }
      if (isExtreme) {
        if (rel.type == R_LARCH_TLS_DESC_CALL)
          continue;
        rel.expr = getRelExpr(rel.type, *rel.sym, loc);
        val = SignExtend64(sec.getRelocTargetVA(ctx, rel, secAddr + rel.offset),
                           bits);
        relocateNoSym(loc, rel.type, val);
      } else {
        isRelax = relaxable(relocs, i);
        if (isRelax && (rel.type == R_LARCH_TLS_DESC_PC_HI20 ||
                        rel.type == R_LARCH_TLS_DESC_PC_LO12 ||
                        (rel.type == R_LARCH_TLS_DESC_LD && isUInt<12>(val))))
          continue;
        tlsdescToLe(loc, rel, val);
      }
      continue;
    default:
      break;
    }
    relocate(loc, rel, val);
  }
}

// When relaxing just R_LARCH_ALIGN, relocDeltas is usually changed only once in
// the absence of a linker script. For call and load/store R_LARCH_RELAX, code
// shrinkage may reduce displacement and make more relocations eligible for
// relaxation. Code shrinkage may increase displacement to a call/load/store
// target at a higher fixed address, invalidating an earlier relaxation. Any
// change in section sizes can have cascading effect and require another
// relaxation pass.
bool LoongArch::relaxOnce(int pass) const {
  if (ctx.arg.relocatable)
    return false;

  if (pass == 0)
    initSymbolAnchors(ctx);

  SmallVector<InputSection *, 0> storage;
  bool changed = false;
  for (OutputSection *osec : ctx.outputSections) {
    if (!(osec->flags & SHF_EXECINSTR))
      continue;
    for (InputSection *sec : getInputSections(*osec, storage))
      changed |= relax(ctx, *sec);
  }
  return changed;
}

void LoongArch::finalizeRelax(int passes) const {
  Log(ctx) << "relaxation passes: " << passes;
  SmallVector<InputSection *, 0> storage;
  for (OutputSection *osec : ctx.outputSections) {
    if (!(osec->flags & SHF_EXECINSTR))
      continue;
    for (InputSection *sec : getInputSections(*osec, storage)) {
      RelaxAux &aux = *sec->relaxAux;
      if (!aux.relocDeltas)
        continue;

      MutableArrayRef<Relocation> rels = sec->relocs();
      ArrayRef<uint8_t> old = sec->content();
      size_t newSize = old.size() - aux.relocDeltas[rels.size() - 1];
      size_t writesIdx = 0;
      uint8_t *p = ctx.bAlloc.Allocate<uint8_t>(newSize);
      uint64_t offset = 0;
      int64_t delta = 0;
      sec->content_ = p;
      sec->size = newSize;
      sec->bytesDropped = 0;

      // Update section content: remove NOPs for R_LARCH_ALIGN and rewrite
      // instructions for relaxed relocations.
      for (size_t i = 0, e = rels.size(); i != e; ++i) {
        uint32_t remove = aux.relocDeltas[i] - delta;
        delta = aux.relocDeltas[i];
        if (remove == 0 && aux.relocTypes[i] == R_LARCH_NONE)
          continue;

        // Copy from last location to the current relocated location.
        Relocation &r = rels[i];
        uint64_t size = r.offset - offset;
        memcpy(p, old.data() + offset, size);
        p += size;

        int64_t skip = 0;
        if (RelType newType = aux.relocTypes[i]) {
          switch (newType) {
          case R_LARCH_RELAX:
            break;
          case R_LARCH_PCREL20_S2:
            skip = 4;
            write32le(p, aux.writes[writesIdx++]);
            // RelExpr is needed for relocating.
            r.expr = r.sym->hasFlag(NEEDS_PLT) ? R_PLT_PC : R_PC;
            break;
          case R_LARCH_B26:
          case R_LARCH_TLS_LE_LO12_R:
            skip = 4;
            write32le(p, aux.writes[writesIdx++]);
            break;
          case R_LARCH_TLS_GD_PCREL20_S2:
            // Note: R_LARCH_TLS_LD_PCREL20_S2 must also use R_TLSGD_PC instead
            // of R_TLSLD_PC due to historical reasons. In fact, right now TLSLD
            // behaves exactly like TLSGD on LoongArch.
            //
            // This reason has also been mentioned in mold commit:
            // https://github.com/rui314/mold/commit/5dfa1cf07c03bd57cb3d493b652ef22441bcd71c
          case R_LARCH_TLS_LD_PCREL20_S2:
            skip = 4;
            write32le(p, aux.writes[writesIdx++]);
            r.expr = R_TLSGD_PC;
            break;
          case R_LARCH_TLS_DESC_PCREL20_S2:
            skip = 4;
            write32le(p, aux.writes[writesIdx++]);
            r.expr = R_TLSDESC_PC;
            break;
          default:
            llvm_unreachable("unsupported type");
          }
        }

        p += skip;
        offset = r.offset + skip + remove;
      }
      memcpy(p, old.data() + offset, old.size() - offset);

      // Subtract the previous relocDeltas value from the relocation offset.
      // For a pair of R_LARCH_XXX/R_LARCH_RELAX with the same offset, decrease
      // their r_offset by the same delta.
      delta = 0;
      for (size_t i = 0, e = rels.size(); i != e;) {
        uint64_t cur = rels[i].offset;
        do {
          rels[i].offset -= delta;
          if (aux.relocTypes[i] != R_LARCH_NONE)
            rels[i].type = aux.relocTypes[i];
        } while (++i != e && rels[i].offset == cur);
        delta = aux.relocDeltas[i - 1];
      }
    }
  }
}

void elf::setLoongArchTargetInfo(Ctx &ctx) {
  ctx.target.reset(new LoongArch(ctx));
}
