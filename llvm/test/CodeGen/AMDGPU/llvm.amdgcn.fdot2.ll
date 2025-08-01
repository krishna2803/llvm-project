; RUN: llc -mtriple=amdgcn -mcpu=gfx906 < %s | FileCheck %s --check-prefixes=GCN,GFX9,GFX906
; RUN: llc -mtriple=amdgcn -mcpu=gfx942 < %s | FileCheck %s --check-prefixes=GCN,GFX9,GFX942
; RUN: llc -mtriple=amdgcn -mcpu=gfx1011 < %s | FileCheck %s --check-prefixes=GCN,GFX10
; RUN: llc -mtriple=amdgcn -mcpu=gfx1012 < %s | FileCheck %s --check-prefixes=GCN,GFX10
; RUN: llc -mtriple=amdgcn -mcpu=gfx1100 -amdgpu-enable-vopd=0 < %s | FileCheck %s --check-prefixes=GCN,GFX10
; RUN: llc -mtriple=amdgcn -mcpu=gfx1200 -amdgpu-enable-vopd=0 < %s | FileCheck %s --check-prefixes=GCN,GFX12

declare float @llvm.amdgcn.fdot2(<2 x half> %a, <2 x half> %b, float %c, i1 %clamp)

; GCN-LABEL: {{^}}test_llvm_amdgcn_fdot2_clamp
; GFX9:   v_dot2_f32_f16 v{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}} clamp{{$}}
; GFX10:  v_dot2_f32_f16 v{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}} clamp{{$}}
; GFX12:  v_dot2_f32_f16 v{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}} clamp{{$}}
define amdgpu_kernel void @test_llvm_amdgcn_fdot2_clamp(
    ptr addrspace(1) %r,
    ptr addrspace(1) %a,
    ptr addrspace(1) %b,
    ptr addrspace(1) %c) {
entry:
  %a.val = load <2 x half>, ptr addrspace(1) %a
  %b.val = load <2 x half>, ptr addrspace(1) %b
  %c.val = load float, ptr addrspace(1) %c
  %r.val = call float @llvm.amdgcn.fdot2(<2 x half> %a.val, <2 x half> %b.val, float %c.val, i1 1)
  store float %r.val, ptr addrspace(1) %r
  ret void
}

; GCN-LABEL: {{^}}test_llvm_amdgcn_fdot2_no_clamp
; GFX906: v_dot2_f32_f16 v{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}{{$}}
; GFX942: v_dot2c_f32_f16_e32 v{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}}{{$}}
; GFX10:  {{v_dot2c_f32_f16|v_dot2acc_f32_f16}} v{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}}{{$}}
; GFX12: v_dot2_f32_f16 v{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}, v{{[0-9]+}}{{$}}
define amdgpu_kernel void @test_llvm_amdgcn_fdot2_no_clamp(
    ptr addrspace(1) %r,
    ptr addrspace(1) %a,
    ptr addrspace(1) %b,
    ptr addrspace(1) %c) {
entry:
  %a.val = load <2 x half>, ptr addrspace(1) %a
  %b.val = load <2 x half>, ptr addrspace(1) %b
  %c.val = load float, ptr addrspace(1) %c
  %r.val = call float @llvm.amdgcn.fdot2(<2 x half> %a.val, <2 x half> %b.val, float %c.val, i1 0)
  store float %r.val, ptr addrspace(1) %r
  ret void
}

; GFX9-LABEL: {{^}}fdot2_inline_literal
; GFX906: v_dot2_f32_f16 v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}, 1.0
; GFX942: v_dot2c_f32_f16_e32 v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}{{$}}
; GFX12: v_dot2_f32_f16 v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}, 1.0{{$}}
define float @fdot2_inline_literal(<2 x half> %a, <2 x half> %b) {
  %ret = tail call float @llvm.amdgcn.fdot2(<2 x half> %a, <2 x half> %b, float 1.0, i1 false)
  ret float %ret
}
