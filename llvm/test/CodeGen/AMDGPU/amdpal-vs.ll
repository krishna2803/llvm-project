; RUN: llc -mtriple=amdgcn--amdpal < %s | FileCheck -check-prefix=GCN %s
; RUN: llc -mtriple=amdgcn--amdpal -mcpu=tonga < %s | FileCheck -check-prefix=GCN %s
; RUN: llc -mtriple=amdgcn--amdpal -mcpu=gfx900 < %s | FileCheck -check-prefix=GCN -enable-var-scope %s

; GCN-LABEL: {{^}}vs_amdpal:
; GCN:         .amdgpu_pal_metadata
; GCN-NEXT: ---
; GCN-NEXT: amdpal.pipelines:
; GCN-NEXT:   - .hardware_stages:
; GCN-NEXT:       .vs:
; GCN-NEXT:         .entry_point:    _amdgpu_vs_main
; GCN-NEXT:         .entry_point_symbol:    vs_amdpal
; GCN-NEXT:         .scratch_memory_size: 0
; GCN:     .registers:
; GCN-NEXT:       '0x2c4a (SPI_SHADER_PGM_RSRC1_VS)': 0
; GCN-NEXT:       '0x2c4b (SPI_SHADER_PGM_RSRC2_VS)': 0
; GCN-NEXT: ...
; GCN-NEXT:         .end_amdgpu_pal_metadata
define amdgpu_vs half @vs_amdpal(half %arg0) {
  %add = fadd half %arg0, 1.0
  ret half %add
}
