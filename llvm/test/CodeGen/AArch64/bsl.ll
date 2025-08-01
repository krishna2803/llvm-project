; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=aarch64-unknown-linux-gnu < %s | FileCheck %s --check-prefix=NEON
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve2 < %s | FileCheck %s --check-prefix=SVE2

; Test SVE2 BSL/NBSL/BSL1N/BSL2N code generation for:
;   #define BSL(x,y,z)   (  ((x) & (z)) | ( (y) & ~(z)))
;   #define NBSL(x,y,z)  (~(((x) & (z)) | ( (y) & ~(z))))
;   #define BSL1N(x,y,z) ( (~(x) & (z)) | ( (y) & ~(z)))
;   #define BSL2N(x,y,z) (  ((x) & (z)) | (~(y) & ~(z)))
;
; See also llvm/test/CodeGen/AArch64/sve2-bsl.ll.

; Test basic codegen.

define <1 x i64> @bsl_v1i64(<1 x i64> %0, <1 x i64> %1, <1 x i64> %2) {
; NEON-LABEL: bsl_v1i64:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl_v1i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    bif v0.8b, v1.8b, v2.8b
; SVE2-NEXT:    ret
  %4 = and <1 x i64> %2, %0
  %5 = xor <1 x i64> %2, splat (i64 -1)
  %6 = and <1 x i64> %1, %5
  %7 = or <1 x i64> %4, %6
  ret <1 x i64> %7
}

define <1 x i64> @nbsl_v1i64(<1 x i64> %0, <1 x i64> %1, <1 x i64> %2) {
; NEON-LABEL: nbsl_v1i64:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    mvn v0.8b, v0.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v1i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <1 x i64> %2, %0
  %5 = xor <1 x i64> %2, splat (i64 -1)
  %6 = and <1 x i64> %1, %5
  %7 = or <1 x i64> %4, %6
  %8 = xor <1 x i64> %7, splat (i64 -1)
  ret <1 x i64> %8
}

define <1 x i64> @bsl1n_v1i64(<1 x i64> %0, <1 x i64> %1, <1 x i64> %2) {
; NEON-LABEL: bsl1n_v1i64:
; NEON:       // %bb.0:
; NEON-NEXT:    mvn v0.8b, v0.8b
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl1n_v1i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    bsl1n z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = xor <1 x i64> %0, splat (i64 -1)
  %5 = and <1 x i64> %2, %4
  %6 = xor <1 x i64> %2, splat (i64 -1)
  %7 = and <1 x i64> %1, %6
  %8 = or <1 x i64> %5, %7
  ret <1 x i64> %8
}

define <1 x i64> @bsl2n_v1i64(<1 x i64> %0, <1 x i64> %1, <1 x i64> %2) {
; NEON-LABEL: bsl2n_v1i64:
; NEON:       // %bb.0:
; NEON-NEXT:    and v0.8b, v2.8b, v0.8b
; NEON-NEXT:    orr v1.8b, v2.8b, v1.8b
; NEON-NEXT:    orn v0.8b, v0.8b, v1.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl2n_v1i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    bsl2n z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <1 x i64> %2, %0
  %5 = or <1 x i64> %2, %1
  %6 = xor <1 x i64> %5, splat (i64 -1)
  %7 = or <1 x i64> %4, %6
  ret <1 x i64> %7
}

define <2 x i64> @bsl_v2i64(<2 x i64> %0, <2 x i64> %1, <2 x i64> %2) {
; NEON-LABEL: bsl_v2i64:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl_v2i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    bif v0.16b, v1.16b, v2.16b
; SVE2-NEXT:    ret
  %4 = and <2 x i64> %2, %0
  %5 = xor <2 x i64> %2, splat (i64 -1)
  %6 = and <2 x i64> %1, %5
  %7 = or <2 x i64> %4, %6
  ret <2 x i64> %7
}

define <2 x i64> @nbsl_v2i64(<2 x i64> %0, <2 x i64> %1, <2 x i64> %2) {
; NEON-LABEL: nbsl_v2i64:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v2i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <2 x i64> %2, %0
  %5 = xor <2 x i64> %2, splat (i64 -1)
  %6 = and <2 x i64> %1, %5
  %7 = or <2 x i64> %4, %6
  %8 = xor <2 x i64> %7, splat (i64 -1)
  ret <2 x i64> %8
}

define <2 x i64> @bsl1n_v2i64(<2 x i64> %0, <2 x i64> %1, <2 x i64> %2) {
; NEON-LABEL: bsl1n_v2i64:
; NEON:       // %bb.0:
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl1n_v2i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    bsl1n z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = xor <2 x i64> %0, splat (i64 -1)
  %5 = and <2 x i64> %2, %4
  %6 = xor <2 x i64> %2, splat (i64 -1)
  %7 = and <2 x i64> %1, %6
  %8 = or <2 x i64> %5, %7
  ret <2 x i64> %8
}

define <2 x i64> @bsl2n_v2i64(<2 x i64> %0, <2 x i64> %1, <2 x i64> %2) {
; NEON-LABEL: bsl2n_v2i64:
; NEON:       // %bb.0:
; NEON-NEXT:    and v0.16b, v2.16b, v0.16b
; NEON-NEXT:    orr v1.16b, v2.16b, v1.16b
; NEON-NEXT:    orn v0.16b, v0.16b, v1.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl2n_v2i64:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    bsl2n z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <2 x i64> %2, %0
  %5 = or <2 x i64> %2, %1
  %6 = xor <2 x i64> %5, splat (i64 -1)
  %7 = or <2 x i64> %4, %6
  ret <2 x i64> %7
}

; Test other element types.

define <8 x i8> @nbsl_v8i8(<8 x i8> %0, <8 x i8> %1, <8 x i8> %2) {
; NEON-LABEL: nbsl_v8i8:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    mvn v0.8b, v0.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v8i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <8 x i8> %2, %0
  %5 = xor <8 x i8> %2, splat (i8 -1)
  %6 = and <8 x i8> %1, %5
  %7 = or <8 x i8> %4, %6
  %8 = xor <8 x i8> %7, splat (i8 -1)
  ret <8 x i8> %8
}

define <4 x i16> @nbsl_v4i16(<4 x i16> %0, <4 x i16> %1, <4 x i16> %2) {
; NEON-LABEL: nbsl_v4i16:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    mvn v0.8b, v0.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v4i16:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <4 x i16> %2, %0
  %5 = xor <4 x i16> %2, splat (i16 -1)
  %6 = and <4 x i16> %1, %5
  %7 = or <4 x i16> %4, %6
  %8 = xor <4 x i16> %7, splat (i16 -1)
  ret <4 x i16> %8
}

define <2 x i32> @nbsl_v2i32(<2 x i32> %0, <2 x i32> %1, <2 x i32> %2) {
; NEON-LABEL: nbsl_v2i32:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.8b, v1.8b, v2.8b
; NEON-NEXT:    mvn v0.8b, v0.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v2i32:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $d0 killed $d0 def $z0
; SVE2-NEXT:    // kill: def $d2 killed $d2 def $z2
; SVE2-NEXT:    // kill: def $d1 killed $d1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $d0 killed $d0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <2 x i32> %2, %0
  %5 = xor <2 x i32> %2, splat (i32 -1)
  %6 = and <2 x i32> %1, %5
  %7 = or <2 x i32> %4, %6
  %8 = xor <2 x i32> %7, splat (i32 -1)
  ret <2 x i32> %8
}

define <16 x i8> @nbsl_v16i8(<16 x i8> %0, <16 x i8> %1, <16 x i8> %2) {
; NEON-LABEL: nbsl_v16i8:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v16i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <16 x i8> %2, %0
  %5 = xor <16 x i8> %2, splat (i8 -1)
  %6 = and <16 x i8> %1, %5
  %7 = or <16 x i8> %4, %6
  %8 = xor <16 x i8> %7, splat (i8 -1)
  ret <16 x i8> %8
}

define <8 x i16> @nbsl_v8i16(<8 x i16> %0, <8 x i16> %1, <8 x i16> %2) {
; NEON-LABEL: nbsl_v8i16:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v8i16:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <8 x i16> %2, %0
  %5 = xor <8 x i16> %2, splat (i16 -1)
  %6 = and <8 x i16> %1, %5
  %7 = or <8 x i16> %4, %6
  %8 = xor <8 x i16> %7, splat (i16 -1)
  ret <8 x i16> %8
}

define <4 x i32> @nbsl_v4i32(<4 x i32> %0, <4 x i32> %1, <4 x i32> %2) {
; NEON-LABEL: nbsl_v4i32:
; NEON:       // %bb.0:
; NEON-NEXT:    bif v0.16b, v1.16b, v2.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v4i32:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q2 killed $q2 def $z2
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z2.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %4 = and <4 x i32> %2, %0
  %5 = xor <4 x i32> %2, splat (i32 -1)
  %6 = and <4 x i32> %1, %5
  %7 = or <4 x i32> %4, %6
  %8 = xor <4 x i32> %7, splat (i32 -1)
  ret <4 x i32> %8
}

; Test types that need promotion.

define <4 x i8> @bsl_v4i8(<4 x i8> %0, <4 x i8> %1, <4 x i8> %2) {
; NEON-LABEL: bsl_v4i8:
; NEON:       // %bb.0:
; NEON-NEXT:    movi d3, #0xff00ff00ff00ff
; NEON-NEXT:    and v0.8b, v2.8b, v0.8b
; NEON-NEXT:    eor v3.8b, v2.8b, v3.8b
; NEON-NEXT:    and v1.8b, v1.8b, v3.8b
; NEON-NEXT:    orr v0.8b, v0.8b, v1.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl_v4i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    movi d3, #0xff00ff00ff00ff
; SVE2-NEXT:    and v0.8b, v2.8b, v0.8b
; SVE2-NEXT:    eor v3.8b, v2.8b, v3.8b
; SVE2-NEXT:    and v1.8b, v1.8b, v3.8b
; SVE2-NEXT:    orr v0.8b, v0.8b, v1.8b
; SVE2-NEXT:    ret
  %4 = and <4 x i8> %2, %0
  %5 = xor <4 x i8> %2, splat (i8 -1)
  %6 = and <4 x i8> %1, %5
  %7 = or <4 x i8> %4, %6
  ret <4 x i8> %7
}

define <4 x i8> @nbsl_v4i8(<4 x i8> %0, <4 x i8> %1, <4 x i8> %2) {
; NEON-LABEL: nbsl_v4i8:
; NEON:       // %bb.0:
; NEON-NEXT:    movi d3, #0xff00ff00ff00ff
; NEON-NEXT:    and v0.8b, v2.8b, v0.8b
; NEON-NEXT:    eor v4.8b, v2.8b, v3.8b
; NEON-NEXT:    and v1.8b, v1.8b, v4.8b
; NEON-NEXT:    orr v0.8b, v0.8b, v1.8b
; NEON-NEXT:    eor v0.8b, v0.8b, v3.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nbsl_v4i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    movi d3, #0xff00ff00ff00ff
; SVE2-NEXT:    and v0.8b, v2.8b, v0.8b
; SVE2-NEXT:    eor v4.8b, v2.8b, v3.8b
; SVE2-NEXT:    and v1.8b, v1.8b, v4.8b
; SVE2-NEXT:    orr v0.8b, v0.8b, v1.8b
; SVE2-NEXT:    eor v0.8b, v0.8b, v3.8b
; SVE2-NEXT:    ret
  %4 = and <4 x i8> %2, %0
  %5 = xor <4 x i8> %2, splat (i8 -1)
  %6 = and <4 x i8> %1, %5
  %7 = or <4 x i8> %4, %6
  %8 = xor <4 x i8> %7, splat (i8 -1)
  ret <4 x i8> %8
}

define <4 x i8> @bsl1n_v4i8(<4 x i8> %0, <4 x i8> %1, <4 x i8> %2) {
; NEON-LABEL: bsl1n_v4i8:
; NEON:       // %bb.0:
; NEON-NEXT:    movi d3, #0xff00ff00ff00ff
; NEON-NEXT:    eor v0.8b, v0.8b, v3.8b
; NEON-NEXT:    eor v3.8b, v2.8b, v3.8b
; NEON-NEXT:    and v0.8b, v2.8b, v0.8b
; NEON-NEXT:    and v1.8b, v1.8b, v3.8b
; NEON-NEXT:    orr v0.8b, v0.8b, v1.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl1n_v4i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    movi d3, #0xff00ff00ff00ff
; SVE2-NEXT:    eor v0.8b, v0.8b, v3.8b
; SVE2-NEXT:    eor v3.8b, v2.8b, v3.8b
; SVE2-NEXT:    and v0.8b, v2.8b, v0.8b
; SVE2-NEXT:    and v1.8b, v1.8b, v3.8b
; SVE2-NEXT:    orr v0.8b, v0.8b, v1.8b
; SVE2-NEXT:    ret
  %4 = xor <4 x i8> %0, splat (i8 -1)
  %5 = and <4 x i8> %2, %4
  %6 = xor <4 x i8> %2, splat (i8 -1)
  %7 = and <4 x i8> %1, %6
  %8 = or <4 x i8> %5, %7
  ret <4 x i8> %8
}

define <4 x i8> @bsl2n_v4i8(<4 x i8> %0, <4 x i8> %1, <4 x i8> %2) {
; NEON-LABEL: bsl2n_v4i8:
; NEON:       // %bb.0:
; NEON-NEXT:    movi d3, #0xff00ff00ff00ff
; NEON-NEXT:    orr v1.8b, v2.8b, v1.8b
; NEON-NEXT:    and v0.8b, v2.8b, v0.8b
; NEON-NEXT:    eor v1.8b, v1.8b, v3.8b
; NEON-NEXT:    orr v0.8b, v0.8b, v1.8b
; NEON-NEXT:    ret
;
; SVE2-LABEL: bsl2n_v4i8:
; SVE2:       // %bb.0:
; SVE2-NEXT:    movi d3, #0xff00ff00ff00ff
; SVE2-NEXT:    orr v1.8b, v2.8b, v1.8b
; SVE2-NEXT:    and v0.8b, v2.8b, v0.8b
; SVE2-NEXT:    eor v1.8b, v1.8b, v3.8b
; SVE2-NEXT:    orr v0.8b, v0.8b, v1.8b
; SVE2-NEXT:    ret
  %4 = and <4 x i8> %2, %0
  %5 = or <4 x i8> %2, %1
  %6 = xor <4 x i8> %5, splat (i8 -1)
  %7 = or <4 x i8> %4, %6
  ret <4 x i8> %7
}

; NOT (a) has a dedicated instruction (MVN).
define <2 x i64> @not_q(<2 x i64> %0) #0 {
; NEON-LABEL: not_q:
; NEON:       // %bb.0:
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: not_q:
; SVE2:       // %bb.0:
; SVE2-NEXT:    mvn v0.16b, v0.16b
; SVE2-NEXT:    ret
  %2 = xor <2 x i64> %0, splat (i64 -1)
  ret <2 x i64> %2
}

; NAND (a, b) = NBSL (a, b, b) = NBSL (b, a, a).
define <2 x i64> @nand_q(<2 x i64> %0, <2 x i64> %1) #0 {
; NEON-LABEL: nand_q:
; NEON:       // %bb.0:
; NEON-NEXT:    and v0.16b, v1.16b, v0.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nand_q:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z1.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %3 = and <2 x i64> %1, %0
  %4 = xor <2 x i64> %3, splat (i64 -1)
  ret <2 x i64> %4
}

; NOR (a, b) = NBSL (a, b, a) = NBSL (b, a, b).
define <2 x i64> @nor_q(<2 x i64> %0, <2 x i64> %1) #0 {
; NEON-LABEL: nor_q:
; NEON:       // %bb.0:
; NEON-NEXT:    orr v0.16b, v1.16b, v0.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: nor_q:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    nbsl z0.d, z0.d, z1.d, z0.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %3 = or <2 x i64> %1, %0
  %4 = xor <2 x i64> %3, splat (i64 -1)
  ret <2 x i64> %4
}

; EON (a, b) = BSL2N (a, a, b) = BSL2N (b, b, a).
define <2 x i64> @eon_q(<2 x i64> %0, <2 x i64> %1) #0 {
; NEON-LABEL: eon_q:
; NEON:       // %bb.0:
; NEON-NEXT:    eor v0.16b, v0.16b, v1.16b
; NEON-NEXT:    mvn v0.16b, v0.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: eon_q:
; SVE2:       // %bb.0:
; SVE2-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE2-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE2-NEXT:    bsl2n z0.d, z0.d, z0.d, z1.d
; SVE2-NEXT:    // kill: def $q0 killed $q0 killed $z0
; SVE2-NEXT:    ret
  %3 = xor <2 x i64> %0, %1
  %4 = xor <2 x i64> %3, splat (i64 -1)
  ret <2 x i64> %4
}

; ORN (a, b) has a dedicated instruction (ORN).
define <2 x i64> @orn_q(<2 x i64> %0, <2 x i64> %1) #0 {
; NEON-LABEL: orn_q:
; NEON:       // %bb.0:
; NEON-NEXT:    orn v0.16b, v0.16b, v1.16b
; NEON-NEXT:    ret
;
; SVE2-LABEL: orn_q:
; SVE2:       // %bb.0:
; SVE2-NEXT:    orn v0.16b, v0.16b, v1.16b
; SVE2-NEXT:    ret
  %3 = xor <2 x i64> %1, splat (i64 -1)
  %4 = or <2 x i64> %0, %3
  ret <2 x i64> %4
}
