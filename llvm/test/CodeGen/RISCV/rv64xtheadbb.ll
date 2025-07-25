; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv64 -verify-machineinstrs < %s \
; RUN:   | FileCheck %s -check-prefix=RV64I
; RUN: llc -mtriple=riscv64 -mattr=+xtheadbb -verify-machineinstrs < %s \
; RUN:   | FileCheck %s -check-prefix=RV64XTHEADBB

declare i32 @llvm.ctlz.i32(i32, i1)

define signext i32 @ctlz_i32(i32 signext %a) nounwind {
; RV64I-LABEL: ctlz_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    beqz a0, .LBB0_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    srliw a1, a0, 1
; RV64I-NEXT:    lui a2, 349525
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    addi a1, a2, 1365
; RV64I-NEXT:    srliw a2, a0, 2
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 4
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 8
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 16
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    not a0, a0
; RV64I-NEXT:    srli a2, a0, 1
; RV64I-NEXT:    and a1, a2, a1
; RV64I-NEXT:    lui a2, 209715
; RV64I-NEXT:    addi a2, a2, 819
; RV64I-NEXT:    sub a0, a0, a1
; RV64I-NEXT:    and a1, a0, a2
; RV64I-NEXT:    srli a0, a0, 2
; RV64I-NEXT:    and a0, a0, a2
; RV64I-NEXT:    lui a2, 61681
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srli a1, a0, 4
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    addi a1, a2, -241
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 8
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 16
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    srliw a0, a0, 24
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB0_2:
; RV64I-NEXT:    li a0, 32
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: ctlz_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    slli a0, a0, 32
; RV64XTHEADBB-NEXT:    th.ff0 a0, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.ctlz.i32(i32 %a, i1 false)
  ret i32 %1
}

define signext i32 @log2_i32(i32 signext %a) nounwind {
; RV64I-LABEL: log2_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    beqz a0, .LBB1_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    srliw a1, a0, 1
; RV64I-NEXT:    lui a2, 349525
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    addi a1, a2, 1365
; RV64I-NEXT:    srliw a2, a0, 2
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 4
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 8
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 16
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    not a0, a0
; RV64I-NEXT:    srli a2, a0, 1
; RV64I-NEXT:    and a1, a2, a1
; RV64I-NEXT:    lui a2, 209715
; RV64I-NEXT:    addi a2, a2, 819
; RV64I-NEXT:    sub a0, a0, a1
; RV64I-NEXT:    and a1, a0, a2
; RV64I-NEXT:    srli a0, a0, 2
; RV64I-NEXT:    and a0, a0, a2
; RV64I-NEXT:    lui a2, 61681
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srli a1, a0, 4
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    addi a1, a2, -241
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 8
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 16
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    srliw a0, a0, 24
; RV64I-NEXT:    j .LBB1_3
; RV64I-NEXT:  .LBB1_2:
; RV64I-NEXT:    li a0, 32
; RV64I-NEXT:  .LBB1_3: # %cond.end
; RV64I-NEXT:    li a1, 31
; RV64I-NEXT:    sub a0, a1, a0
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: log2_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    slli a0, a0, 32
; RV64XTHEADBB-NEXT:    th.ff0 a0, a0
; RV64XTHEADBB-NEXT:    li a1, 31
; RV64XTHEADBB-NEXT:    sub a0, a1, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.ctlz.i32(i32 %a, i1 false)
  %2 = sub i32 31, %1
  ret i32 %2
}

define signext i32 @log2_ceil_i32(i32 signext %a) nounwind {
; RV64I-LABEL: log2_ceil_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    addiw a1, a0, -1
; RV64I-NEXT:    li a0, 32
; RV64I-NEXT:    li a2, 32
; RV64I-NEXT:    beqz a1, .LBB2_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    srliw a2, a1, 1
; RV64I-NEXT:    lui a3, 349525
; RV64I-NEXT:    or a1, a1, a2
; RV64I-NEXT:    addi a2, a3, 1365
; RV64I-NEXT:    srliw a3, a1, 2
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 4
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 8
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 16
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    not a1, a1
; RV64I-NEXT:    srli a3, a1, 1
; RV64I-NEXT:    and a2, a3, a2
; RV64I-NEXT:    lui a3, 209715
; RV64I-NEXT:    addi a3, a3, 819
; RV64I-NEXT:    sub a1, a1, a2
; RV64I-NEXT:    and a2, a1, a3
; RV64I-NEXT:    srli a1, a1, 2
; RV64I-NEXT:    and a1, a1, a3
; RV64I-NEXT:    lui a3, 61681
; RV64I-NEXT:    add a1, a2, a1
; RV64I-NEXT:    srli a2, a1, 4
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    addi a2, a3, -241
; RV64I-NEXT:    and a1, a1, a2
; RV64I-NEXT:    slli a2, a1, 8
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    slli a2, a1, 16
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    srliw a2, a1, 24
; RV64I-NEXT:  .LBB2_2: # %cond.end
; RV64I-NEXT:    sub a0, a0, a2
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: log2_ceil_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    addi a0, a0, -1
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    slli a0, a0, 32
; RV64XTHEADBB-NEXT:    th.ff0 a0, a0
; RV64XTHEADBB-NEXT:    li a1, 32
; RV64XTHEADBB-NEXT:    sub a0, a1, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = sub i32 %a, 1
  %2 = call i32 @llvm.ctlz.i32(i32 %1, i1 false)
  %3 = sub i32 32, %2
  ret i32 %3
}

define signext i32 @findLastSet_i32(i32 signext %a) nounwind {
; RV64I-LABEL: findLastSet_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srliw a1, a0, 1
; RV64I-NEXT:    lui a2, 349525
; RV64I-NEXT:    or a1, a0, a1
; RV64I-NEXT:    addi a2, a2, 1365
; RV64I-NEXT:    srliw a3, a1, 2
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 4
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 8
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srliw a3, a1, 16
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    not a1, a1
; RV64I-NEXT:    srli a3, a1, 1
; RV64I-NEXT:    and a2, a3, a2
; RV64I-NEXT:    lui a3, 209715
; RV64I-NEXT:    addi a3, a3, 819
; RV64I-NEXT:    sub a1, a1, a2
; RV64I-NEXT:    and a2, a1, a3
; RV64I-NEXT:    srli a1, a1, 2
; RV64I-NEXT:    and a1, a1, a3
; RV64I-NEXT:    lui a3, 61681
; RV64I-NEXT:    snez a0, a0
; RV64I-NEXT:    addi a3, a3, -241
; RV64I-NEXT:    add a1, a2, a1
; RV64I-NEXT:    srli a2, a1, 4
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    and a1, a1, a3
; RV64I-NEXT:    slli a2, a1, 8
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    slli a2, a1, 16
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    srliw a1, a1, 24
; RV64I-NEXT:    xori a1, a1, 31
; RV64I-NEXT:    addi a0, a0, -1
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: findLastSet_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    not a1, a0
; RV64XTHEADBB-NEXT:    snez a0, a0
; RV64XTHEADBB-NEXT:    slli a1, a1, 32
; RV64XTHEADBB-NEXT:    th.ff0 a1, a1
; RV64XTHEADBB-NEXT:    xori a1, a1, 31
; RV64XTHEADBB-NEXT:    addi a0, a0, -1
; RV64XTHEADBB-NEXT:    or a0, a0, a1
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.ctlz.i32(i32 %a, i1 true)
  %2 = xor i32 31, %1
  %3 = icmp eq i32 %a, 0
  %4 = select i1 %3, i32 -1, i32 %2
  ret i32 %4
}

define i32 @ctlz_lshr_i32(i32 signext %a) {
; RV64I-LABEL: ctlz_lshr_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srliw a0, a0, 1
; RV64I-NEXT:    beqz a0, .LBB4_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    srliw a1, a0, 1
; RV64I-NEXT:    lui a2, 349525
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    addi a1, a2, 1365
; RV64I-NEXT:    srliw a2, a0, 2
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 4
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 8
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    srliw a2, a0, 16
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    not a0, a0
; RV64I-NEXT:    srli a2, a0, 1
; RV64I-NEXT:    and a1, a2, a1
; RV64I-NEXT:    lui a2, 209715
; RV64I-NEXT:    addi a2, a2, 819
; RV64I-NEXT:    sub a0, a0, a1
; RV64I-NEXT:    and a1, a0, a2
; RV64I-NEXT:    srli a0, a0, 2
; RV64I-NEXT:    and a0, a0, a2
; RV64I-NEXT:    lui a2, 61681
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srli a1, a0, 4
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    addi a1, a2, -241
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 8
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 16
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    srliw a0, a0, 24
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB4_2:
; RV64I-NEXT:    li a0, 32
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: ctlz_lshr_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    srliw a0, a0, 1
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    slli a0, a0, 32
; RV64XTHEADBB-NEXT:    th.ff0 a0, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = lshr i32 %a, 1
  %2 = call i32 @llvm.ctlz.i32(i32 %1, i1 false)
  ret i32 %2
}

declare i64 @llvm.ctlz.i64(i64, i1)

define i64 @ctlz_i64(i64 %a) nounwind {
; RV64I-LABEL: ctlz_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    beqz a0, .LBB5_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    srli a1, a0, 1
; RV64I-NEXT:    lui a2, 349525
; RV64I-NEXT:    lui a3, 209715
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    addi a1, a2, 1365
; RV64I-NEXT:    addi a2, a3, 819
; RV64I-NEXT:    srli a3, a0, 2
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    slli a3, a1, 32
; RV64I-NEXT:    add a1, a1, a3
; RV64I-NEXT:    slli a3, a2, 32
; RV64I-NEXT:    add a2, a2, a3
; RV64I-NEXT:    srli a3, a0, 4
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    srli a3, a0, 8
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    srli a3, a0, 16
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    srli a3, a0, 32
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    not a0, a0
; RV64I-NEXT:    srli a3, a0, 1
; RV64I-NEXT:    and a1, a3, a1
; RV64I-NEXT:    lui a3, 61681
; RV64I-NEXT:    addi a3, a3, -241
; RV64I-NEXT:    sub a0, a0, a1
; RV64I-NEXT:    and a1, a0, a2
; RV64I-NEXT:    srli a0, a0, 2
; RV64I-NEXT:    and a0, a0, a2
; RV64I-NEXT:    slli a2, a3, 32
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srli a1, a0, 4
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    add a2, a3, a2
; RV64I-NEXT:    and a0, a0, a2
; RV64I-NEXT:    slli a1, a0, 8
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 16
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 32
; RV64I-NEXT:    add a0, a0, a1
; RV64I-NEXT:    srli a0, a0, 56
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB5_2:
; RV64I-NEXT:    li a0, 64
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: ctlz_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ff1 a0, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = call i64 @llvm.ctlz.i64(i64 %a, i1 false)
  ret i64 %1
}

declare i32 @llvm.cttz.i32(i32, i1)

define signext i32 @cttz_i32(i32 signext %a) nounwind {
; RV64I-LABEL: cttz_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    beqz a0, .LBB6_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    neg a1, a0
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 6
; RV64I-NEXT:    slli a2, a0, 8
; RV64I-NEXT:    slli a3, a0, 10
; RV64I-NEXT:    slli a4, a0, 12
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    slli a2, a0, 16
; RV64I-NEXT:    sub a3, a3, a4
; RV64I-NEXT:    slli a4, a0, 18
; RV64I-NEXT:    sub a2, a2, a4
; RV64I-NEXT:    slli a4, a0, 4
; RV64I-NEXT:    sub a4, a0, a4
; RV64I-NEXT:    add a1, a4, a1
; RV64I-NEXT:    slli a4, a0, 14
; RV64I-NEXT:    sub a3, a3, a4
; RV64I-NEXT:    slli a4, a0, 23
; RV64I-NEXT:    sub a2, a2, a4
; RV64I-NEXT:    slli a0, a0, 27
; RV64I-NEXT:    add a1, a1, a3
; RV64I-NEXT:    add a0, a2, a0
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srliw a0, a0, 27
; RV64I-NEXT:    lui a1, %hi(.LCPI6_0)
; RV64I-NEXT:    addi a1, a1, %lo(.LCPI6_0)
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    lbu a0, 0(a0)
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB6_2:
; RV64I-NEXT:    li a0, 32
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: cttz_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    beqz a0, .LBB6_2
; RV64XTHEADBB-NEXT:  # %bb.1: # %cond.false
; RV64XTHEADBB-NEXT:    addi a1, a0, -1
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    and a0, a0, a1
; RV64XTHEADBB-NEXT:    th.ff1 a0, a0
; RV64XTHEADBB-NEXT:    li a1, 64
; RV64XTHEADBB-NEXT:    sub a0, a1, a0
; RV64XTHEADBB-NEXT:    ret
; RV64XTHEADBB-NEXT:  .LBB6_2:
; RV64XTHEADBB-NEXT:    li a0, 32
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.cttz.i32(i32 %a, i1 false)
  ret i32 %1
}

define signext i32 @cttz_zero_undef_i32(i32 signext %a) nounwind {
; RV64I-LABEL: cttz_zero_undef_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    neg a1, a0
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    slli a1, a0, 6
; RV64I-NEXT:    slli a2, a0, 8
; RV64I-NEXT:    slli a3, a0, 10
; RV64I-NEXT:    slli a4, a0, 12
; RV64I-NEXT:    add a1, a1, a2
; RV64I-NEXT:    slli a2, a0, 16
; RV64I-NEXT:    sub a3, a3, a4
; RV64I-NEXT:    slli a4, a0, 18
; RV64I-NEXT:    sub a2, a2, a4
; RV64I-NEXT:    slli a4, a0, 4
; RV64I-NEXT:    sub a4, a0, a4
; RV64I-NEXT:    add a1, a4, a1
; RV64I-NEXT:    slli a4, a0, 14
; RV64I-NEXT:    sub a3, a3, a4
; RV64I-NEXT:    slli a4, a0, 23
; RV64I-NEXT:    sub a2, a2, a4
; RV64I-NEXT:    slli a0, a0, 27
; RV64I-NEXT:    add a1, a1, a3
; RV64I-NEXT:    add a0, a2, a0
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    srliw a0, a0, 27
; RV64I-NEXT:    lui a1, %hi(.LCPI7_0)
; RV64I-NEXT:    addi a1, a1, %lo(.LCPI7_0)
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    lbu a0, 0(a0)
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: cttz_zero_undef_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    addi a1, a0, -1
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    and a0, a0, a1
; RV64XTHEADBB-NEXT:    th.ff1 a0, a0
; RV64XTHEADBB-NEXT:    li a1, 64
; RV64XTHEADBB-NEXT:    sub a0, a1, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.cttz.i32(i32 %a, i1 true)
  ret i32 %1
}

define signext i32 @findFirstSet_i32(i32 signext %a) nounwind {
; RV64I-LABEL: findFirstSet_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    neg a1, a0
; RV64I-NEXT:    and a1, a0, a1
; RV64I-NEXT:    slli a2, a1, 6
; RV64I-NEXT:    slli a3, a1, 8
; RV64I-NEXT:    slli a4, a1, 10
; RV64I-NEXT:    slli a5, a1, 12
; RV64I-NEXT:    add a2, a2, a3
; RV64I-NEXT:    slli a3, a1, 16
; RV64I-NEXT:    sub a4, a4, a5
; RV64I-NEXT:    slli a5, a1, 18
; RV64I-NEXT:    sub a3, a3, a5
; RV64I-NEXT:    slli a5, a1, 4
; RV64I-NEXT:    sub a5, a1, a5
; RV64I-NEXT:    add a2, a5, a2
; RV64I-NEXT:    slli a5, a1, 14
; RV64I-NEXT:    sub a4, a4, a5
; RV64I-NEXT:    slli a5, a1, 23
; RV64I-NEXT:    sub a3, a3, a5
; RV64I-NEXT:    slli a1, a1, 27
; RV64I-NEXT:    add a2, a2, a4
; RV64I-NEXT:    add a1, a3, a1
; RV64I-NEXT:    add a1, a2, a1
; RV64I-NEXT:    srliw a1, a1, 27
; RV64I-NEXT:    lui a2, %hi(.LCPI8_0)
; RV64I-NEXT:    addi a2, a2, %lo(.LCPI8_0)
; RV64I-NEXT:    add a1, a2, a1
; RV64I-NEXT:    lbu a1, 0(a1)
; RV64I-NEXT:    snez a0, a0
; RV64I-NEXT:    addi a0, a0, -1
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: findFirstSet_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    addi a1, a0, -1
; RV64XTHEADBB-NEXT:    not a2, a0
; RV64XTHEADBB-NEXT:    and a1, a2, a1
; RV64XTHEADBB-NEXT:    li a2, 64
; RV64XTHEADBB-NEXT:    snez a0, a0
; RV64XTHEADBB-NEXT:    th.ff1 a1, a1
; RV64XTHEADBB-NEXT:    sub a2, a2, a1
; RV64XTHEADBB-NEXT:    addi a0, a0, -1
; RV64XTHEADBB-NEXT:    or a0, a0, a2
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.cttz.i32(i32 %a, i1 true)
  %2 = icmp eq i32 %a, 0
  %3 = select i1 %2, i32 -1, i32 %1
  ret i32 %3
}

define signext i32 @ffs_i32(i32 signext %a) nounwind {
; RV64I-LABEL: ffs_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    neg a1, a0
; RV64I-NEXT:    and a1, a0, a1
; RV64I-NEXT:    slli a2, a1, 6
; RV64I-NEXT:    slli a3, a1, 8
; RV64I-NEXT:    slli a4, a1, 10
; RV64I-NEXT:    slli a5, a1, 12
; RV64I-NEXT:    add a2, a2, a3
; RV64I-NEXT:    slli a3, a1, 16
; RV64I-NEXT:    sub a4, a4, a5
; RV64I-NEXT:    slli a5, a1, 18
; RV64I-NEXT:    sub a3, a3, a5
; RV64I-NEXT:    slli a5, a1, 4
; RV64I-NEXT:    sub a5, a1, a5
; RV64I-NEXT:    add a2, a5, a2
; RV64I-NEXT:    slli a5, a1, 14
; RV64I-NEXT:    sub a4, a4, a5
; RV64I-NEXT:    slli a5, a1, 23
; RV64I-NEXT:    sub a3, a3, a5
; RV64I-NEXT:    add a2, a2, a4
; RV64I-NEXT:    lui a4, %hi(.LCPI9_0)
; RV64I-NEXT:    addi a4, a4, %lo(.LCPI9_0)
; RV64I-NEXT:    slli a1, a1, 27
; RV64I-NEXT:    add a1, a3, a1
; RV64I-NEXT:    add a1, a2, a1
; RV64I-NEXT:    srliw a1, a1, 27
; RV64I-NEXT:    add a1, a4, a1
; RV64I-NEXT:    lbu a1, 0(a1)
; RV64I-NEXT:    seqz a0, a0
; RV64I-NEXT:    addi a1, a1, 1
; RV64I-NEXT:    addi a0, a0, -1
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: ffs_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    addi a1, a0, -1
; RV64XTHEADBB-NEXT:    not a2, a0
; RV64XTHEADBB-NEXT:    and a1, a2, a1
; RV64XTHEADBB-NEXT:    li a2, 65
; RV64XTHEADBB-NEXT:    seqz a0, a0
; RV64XTHEADBB-NEXT:    th.ff1 a1, a1
; RV64XTHEADBB-NEXT:    sub a2, a2, a1
; RV64XTHEADBB-NEXT:    addi a0, a0, -1
; RV64XTHEADBB-NEXT:    and a0, a0, a2
; RV64XTHEADBB-NEXT:    ret
  %1 = call i32 @llvm.cttz.i32(i32 %a, i1 true)
  %2 = add i32 %1, 1
  %3 = icmp eq i32 %a, 0
  %4 = select i1 %3, i32 0, i32 %2
  ret i32 %4
}

declare i64 @llvm.cttz.i64(i64, i1)

define i64 @cttz_i64(i64 %a) nounwind {
; RV64I-LABEL: cttz_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    beqz a0, .LBB10_2
; RV64I-NEXT:  # %bb.1: # %cond.false
; RV64I-NEXT:    addi sp, sp, -16
; RV64I-NEXT:    sd ra, 8(sp) # 8-byte Folded Spill
; RV64I-NEXT:    neg a1, a0
; RV64I-NEXT:    and a0, a0, a1
; RV64I-NEXT:    lui a1, %hi(.LCPI10_0)
; RV64I-NEXT:    ld a1, %lo(.LCPI10_0)(a1)
; RV64I-NEXT:    call __muldi3
; RV64I-NEXT:    srli a0, a0, 58
; RV64I-NEXT:    lui a1, %hi(.LCPI10_1)
; RV64I-NEXT:    addi a1, a1, %lo(.LCPI10_1)
; RV64I-NEXT:    add a0, a1, a0
; RV64I-NEXT:    lbu a0, 0(a0)
; RV64I-NEXT:    ld ra, 8(sp) # 8-byte Folded Reload
; RV64I-NEXT:    addi sp, sp, 16
; RV64I-NEXT:    ret
; RV64I-NEXT:  .LBB10_2:
; RV64I-NEXT:    li a0, 64
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: cttz_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    beqz a0, .LBB10_2
; RV64XTHEADBB-NEXT:  # %bb.1: # %cond.false
; RV64XTHEADBB-NEXT:    addi a1, a0, -1
; RV64XTHEADBB-NEXT:    not a0, a0
; RV64XTHEADBB-NEXT:    and a0, a0, a1
; RV64XTHEADBB-NEXT:    th.ff1 a0, a0
; RV64XTHEADBB-NEXT:    li a1, 64
; RV64XTHEADBB-NEXT:    sub a0, a1, a0
; RV64XTHEADBB-NEXT:    ret
; RV64XTHEADBB-NEXT:  .LBB10_2:
; RV64XTHEADBB-NEXT:    li a0, 64
; RV64XTHEADBB-NEXT:    ret
  %1 = call i64 @llvm.cttz.i64(i64 %a, i1 false)
  ret i64 %1
}

define signext i32 @sexti1_i32(i32 signext %a) nounwind {
; RV64I-LABEL: sexti1_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 63
; RV64I-NEXT:    srai a0, a0, 63
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexti1_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 0, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i32 %a, 31
  %shr = ashr exact i32 %shl, 31
  ret i32 %shr
}

define signext i32 @sexti1_i32_2(i1 %a) nounwind {
; RV64I-LABEL: sexti1_i32_2:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 63
; RV64I-NEXT:    srai a0, a0, 63
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexti1_i32_2:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 0, 0
; RV64XTHEADBB-NEXT:    ret
  %sext = sext i1 %a to i32
  ret i32 %sext
}

define i64 @sexti1_i64(i64 %a) nounwind {
; RV64I-LABEL: sexti1_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 63
; RV64I-NEXT:    srai a0, a0, 63
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexti1_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 0, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i64 %a, 63
  %shr = ashr exact i64 %shl, 63
  ret i64 %shr
}

define i64 @sexti1_i64_2(i1 %a) nounwind {
; RV64I-LABEL: sexti1_i64_2:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 63
; RV64I-NEXT:    srai a0, a0, 63
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexti1_i64_2:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 0, 0
; RV64XTHEADBB-NEXT:    ret
  %sext = sext i1 %a to i64
  ret i64 %sext
}

define signext i32 @sextb_i32(i32 signext %a) nounwind {
; RV64I-LABEL: sextb_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 56
; RV64I-NEXT:    srai a0, a0, 56
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sextb_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 7, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i32 %a, 24
  %shr = ashr exact i32 %shl, 24
  ret i32 %shr
}

define i64 @sextb_i64(i64 %a) nounwind {
; RV64I-LABEL: sextb_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 56
; RV64I-NEXT:    srai a0, a0, 56
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sextb_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 7, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i64 %a, 56
  %shr = ashr exact i64 %shl, 56
  ret i64 %shr
}

define signext i32 @sexth_i32(i32 signext %a) nounwind {
; RV64I-LABEL: sexth_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 48
; RV64I-NEXT:    srai a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexth_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 15, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i32 %a, 16
  %shr = ashr exact i32 %shl, 16
  ret i32 %shr
}

define signext i32 @no_sexth_i32(i32 signext %a) nounwind {
; RV64I-LABEL: no_sexth_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 49
; RV64I-NEXT:    srai a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: no_sexth_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    slli a0, a0, 49
; RV64XTHEADBB-NEXT:    srai a0, a0, 48
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i32 %a, 17
  %shr = ashr exact i32 %shl, 16
  ret i32 %shr
}

define i64 @sexth_i64(i64 %a) nounwind {
; RV64I-LABEL: sexth_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 48
; RV64I-NEXT:    srai a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: sexth_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.ext a0, a0, 15, 0
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i64 %a, 48
  %shr = ashr exact i64 %shl, 48
  ret i64 %shr
}

define i64 @no_sexth_i64(i64 %a) nounwind {
; RV64I-LABEL: no_sexth_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 49
; RV64I-NEXT:    srai a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: no_sexth_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    slli a0, a0, 49
; RV64XTHEADBB-NEXT:    srai a0, a0, 48
; RV64XTHEADBB-NEXT:    ret
  %shl = shl i64 %a, 49
  %shr = ashr exact i64 %shl, 48
  ret i64 %shr
}

define i32 @zexth_i32(i32 %a) nounwind {
; RV64I-LABEL: zexth_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 48
; RV64I-NEXT:    srli a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: zexth_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.extu a0, a0, 15, 0
; RV64XTHEADBB-NEXT:    ret
  %and = and i32 %a, 65535
  ret i32 %and
}

define i64 @zexth_i64(i64 %a) nounwind {
; RV64I-LABEL: zexth_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 48
; RV64I-NEXT:    srli a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: zexth_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.extu a0, a0, 15, 0
; RV64XTHEADBB-NEXT:    ret
  %and = and i64 %a, 65535
  ret i64 %and
}

define i64 @zext_bf_i64(i64 %a) nounwind {
; RV64I-LABEL: zext_bf_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 47
; RV64I-NEXT:    srli a0, a0, 48
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: zext_bf_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.extu a0, a0, 16, 1
; RV64XTHEADBB-NEXT:    ret
  %1 = lshr i64 %a, 1
  %and = and i64 %1, 65535
  ret i64 %and
}

define i64 @zext_bf2_i64(i64 %a) nounwind {
; RV64I-LABEL: zext_bf2_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    slli a0, a0, 48
; RV64I-NEXT:    srli a0, a0, 49
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: zext_bf2_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.extu a0, a0, 15, 1
; RV64XTHEADBB-NEXT:    ret
  %t0 = and i64 %a, 65535
  %result = lshr i64 %t0, 1
  ret i64 %result
}

define i64 @zext_i64_srliw(i64 %a) nounwind {
; RV64I-LABEL: zext_i64_srliw:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srliw a0, a0, 16
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: zext_i64_srliw:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    srliw a0, a0, 16
; RV64XTHEADBB-NEXT:    ret
  %1 = lshr i64 %a, 16
  %and = and i64 %1, 65535
  ret i64 %and
}

declare i32 @llvm.bswap.i32(i32)

define signext i32 @bswap_i32(i32 signext %a) nounwind {
; RV64I-LABEL: bswap_i32:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srli a1, a0, 8
; RV64I-NEXT:    lui a2, 16
; RV64I-NEXT:    srliw a3, a0, 24
; RV64I-NEXT:    addi a2, a2, -256
; RV64I-NEXT:    and a1, a1, a2
; RV64I-NEXT:    and a2, a0, a2
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    slli a2, a2, 8
; RV64I-NEXT:    slliw a0, a0, 24
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: bswap_i32:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.revw a0, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = tail call i32 @llvm.bswap.i32(i32 %a)
  ret i32 %1
}

; Similar to bswap_i32 but the result is not sign extended.
define void @bswap_i32_nosext(i32 signext %a, ptr %x) nounwind {
; RV64I-LABEL: bswap_i32_nosext:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srli a2, a0, 8
; RV64I-NEXT:    lui a3, 16
; RV64I-NEXT:    srliw a4, a0, 24
; RV64I-NEXT:    addi a3, a3, -256
; RV64I-NEXT:    and a2, a2, a3
; RV64I-NEXT:    and a3, a0, a3
; RV64I-NEXT:    or a2, a2, a4
; RV64I-NEXT:    slli a3, a3, 8
; RV64I-NEXT:    slli a0, a0, 24
; RV64I-NEXT:    or a0, a0, a3
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    sw a0, 0(a1)
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: bswap_i32_nosext:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.revw a0, a0
; RV64XTHEADBB-NEXT:    sw a0, 0(a1)
; RV64XTHEADBB-NEXT:    ret
  %1 = tail call i32 @llvm.bswap.i32(i32 %a)
  store i32 %1, ptr %x
  ret void
}

declare i64 @llvm.bswap.i64(i64)

define i64 @bswap_i64(i64 %a) {
; RV64I-LABEL: bswap_i64:
; RV64I:       # %bb.0:
; RV64I-NEXT:    srli a1, a0, 40
; RV64I-NEXT:    lui a2, 16
; RV64I-NEXT:    srli a3, a0, 56
; RV64I-NEXT:    srli a4, a0, 24
; RV64I-NEXT:    lui a5, 4080
; RV64I-NEXT:    addi a2, a2, -256
; RV64I-NEXT:    and a1, a1, a2
; RV64I-NEXT:    or a1, a1, a3
; RV64I-NEXT:    srli a3, a0, 8
; RV64I-NEXT:    and a4, a4, a5
; RV64I-NEXT:    srliw a3, a3, 24
; RV64I-NEXT:    slli a3, a3, 24
; RV64I-NEXT:    or a3, a3, a4
; RV64I-NEXT:    srliw a4, a0, 24
; RV64I-NEXT:    and a5, a0, a5
; RV64I-NEXT:    and a2, a0, a2
; RV64I-NEXT:    slli a0, a0, 56
; RV64I-NEXT:    slli a4, a4, 32
; RV64I-NEXT:    slli a5, a5, 24
; RV64I-NEXT:    or a4, a5, a4
; RV64I-NEXT:    slli a2, a2, 40
; RV64I-NEXT:    or a1, a3, a1
; RV64I-NEXT:    or a0, a0, a2
; RV64I-NEXT:    or a0, a0, a4
; RV64I-NEXT:    or a0, a0, a1
; RV64I-NEXT:    ret
;
; RV64XTHEADBB-LABEL: bswap_i64:
; RV64XTHEADBB:       # %bb.0:
; RV64XTHEADBB-NEXT:    th.rev a0, a0
; RV64XTHEADBB-NEXT:    ret
  %1 = call i64 @llvm.bswap.i64(i64 %a)
  ret i64 %1
}
