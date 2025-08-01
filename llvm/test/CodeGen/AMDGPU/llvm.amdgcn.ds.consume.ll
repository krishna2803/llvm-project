; RUN: llc -global-isel=0 -mtriple=amdgcn -mcpu=tahiti < %s | FileCheck -check-prefixes=GCN,SI,NOTGFX9 %s
; XUN: llc -global-isel=1 -mtriple=amdgcn -mcpu=tahiti < %s | FileCheck -check-prefixes=GCN,SI,NOTGFX9 %s
; RUN: llc -global-isel=0 -mtriple=amdgcn -mcpu=bonaire < %s | FileCheck -check-prefixes=GCN,CIPLUS,NOTGFX9 %s
; RUN: llc -global-isel=1 -mtriple=amdgcn -mcpu=bonaire < %s | FileCheck -check-prefixes=GCN,CIPLUS,NOTGFX9 %s
; RUN: llc -global-isel=0 -mtriple=amdgcn -mcpu=tonga < %s | FileCheck -check-prefixes=GCN,CIPLUS,NOTGFX9 %s
; RUN: llc -global-isel=1 -mtriple=amdgcn -mcpu=tonga < %s | FileCheck -check-prefixes=GCN,CIPLUS,NOTGFX9 %s
; RUN: llc -global-isel=0 -mtriple=amdgcn -mcpu=gfx900 < %s | FileCheck -check-prefixes=GCN,CIPLUS,GFX9 %s
; RUN: llc -global-isel=1 -mtriple=amdgcn -mcpu=gfx900 < %s | FileCheck -check-prefixes=GCN,CIPLUS,GFX9 %s

; GCN-LABEL: {{^}}ds_consume_lds:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]]{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_lds(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %lds, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_lds_max_offset:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]] offset:65532{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_lds_max_offset(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %gep = getelementptr inbounds i32, ptr addrspace(3) %lds, i32 16383
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %gep, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_no_fold_offset_si:
; GCN: s_load_dword [[PTR:s[0-9]+]]

; SI: s_add_i32 m0, [[PTR]], 16
; SI: ds_consume [[RESULT:v[0-9]+]]{{$}}

; CIPLUS: s_mov_b32 m0, [[PTR]]
; CIPLUS: ds_consume [[RESULT:v[0-9]+]] offset:16{{$}}

; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_no_fold_offset_si(ptr addrspace(4) %lds.ptr, ptr addrspace(1) %out) #0 {
  %lds = load ptr addrspace(3), ptr addrspace(4) %lds.ptr, align 4
  %gep = getelementptr inbounds i32, ptr addrspace(3) %lds, i32 4
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %gep, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_lds_over_max_offset:
; GCN: s_load_dword [[PTR:s[0-9]+]]

; SI: s_or_b32 m0, [[PTR]], 0x10000
; CIPLUS: s_add_{{i|u}}32 m0, [[PTR]], 0x10000
; GCN: ds_consume [[RESULT:v[0-9]+]]{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_lds_over_max_offset(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %gep = getelementptr inbounds i32, ptr addrspace(3) %lds, i32 16384
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %gep, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_lds_vgpr_addr:
; GCN: v_readfirstlane_b32 [[READLANE:s[0-9]+]], v0
; GCN: s_mov_b32 m0, [[READLANE]]
; GCN: ds_consume [[RESULT:v[0-9]+]]{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define void @ds_consume_lds_vgpr_addr(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %lds, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_gds:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]] gds{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_gds(ptr addrspace(2) %gds, ptr addrspace(1) %out) #0 {
  %val = call i32 @llvm.amdgcn.ds.consume.p2(ptr addrspace(2) %gds, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_gds_max_offset:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]] offset:65532 gds{{$}}
; GCN-NOT: buffer_wbinvl1
; GCN: {{.*}}store{{.*}} [[RESULT]]
define amdgpu_kernel void @ds_consume_gds_max_offset(ptr addrspace(2) %gds, ptr addrspace(1) %out) #0 {
  %gep = getelementptr inbounds i32, ptr addrspace(2) %gds, i32 16383
  %val = call i32 @llvm.amdgcn.ds.consume.p2(ptr addrspace(2) %gep, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_gds_over_max_offset:
; GCN-NOT: buffer_wbinvl1
define amdgpu_kernel void @ds_consume_gds_over_max_offset(ptr addrspace(2) %gds, ptr addrspace(1) %out) #0 {
  %gep = getelementptr inbounds i32, ptr addrspace(2) %gds, i32 16384
  %val = call i32 @llvm.amdgcn.ds.consume.p2(ptr addrspace(2) %gep, i1 false)
  store i32 %val, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}ds_consume_lds_m0_restore:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]]{{$}}
; GCN-NOT: buffer_wbinvl1
; NOTGFX9: s_mov_b32 m0, -1
; GFX9-NOT: m0
; GCN: _store_dword
; GCN: ds_read_b32
define amdgpu_kernel void @ds_consume_lds_m0_restore(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %val0 = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %lds, i1 false)
  store i32 %val0, ptr addrspace(1) %out
  %val1 = load volatile i32, ptr addrspace(3) %lds
  ret void
}

; Make sure this selects successfully with no use. The result register needs to be constrained.
; GCN-LABEL: {{^}}ds_consume_lds_no_use:
; GCN: s_load_dword [[PTR:s[0-9]+]]
; GCN: s_mov_b32 m0, [[PTR]]
; GCN: ds_consume [[RESULT:v[0-9]+]] offset:65532{{$}}
define amdgpu_kernel void @ds_consume_lds_no_use(ptr addrspace(3) %lds, ptr addrspace(1) %out) #0 {
  %gep = getelementptr inbounds i32, ptr addrspace(3) %lds, i32 16383
  %val = call i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) %gep, i1 false)
  ret void
}

declare i32 @llvm.amdgcn.ds.consume.p3(ptr addrspace(3) nocapture, i1 immarg) #1
declare i32 @llvm.amdgcn.ds.consume.p2(ptr addrspace(2) nocapture, i1 immarg) #1

attributes #0 = { nounwind }
attributes #1 = { argmemonly convergent nounwind }
