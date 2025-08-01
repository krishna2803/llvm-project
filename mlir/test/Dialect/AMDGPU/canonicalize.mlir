// RUN: mlir-opt %s -split-input-file -canonicalize="test-convergence" | FileCheck %s

// CHECK-LABEL: func @known_oob_load
func.func @known_oob_load(%arg0: memref<4xf32>) -> f32 {
  // CHECK: %[[zero:.*]] = arith.constant 0.000000e+00 : f32
  // CHECK: return %[[zero]]
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c4_i32] : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @known_oob_load_2d
func.func @known_oob_load_2d(%arg0: memref<4x4xf32>) -> f32 {
  // CHECK: %[[zero:.*]] = arith.constant 0.000000e+00 : f32
  // CHECK: return %[[zero]]
  %c0_i32 = arith.constant 0 : i32
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c4_i32, %c0_i32] : memref<4x4xf32>, i32, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @known_oob_load_2d_on_last
func.func @known_oob_load_2d_on_last(%arg0: memref<4x4xf32>) -> f32 {
  // CHECK: %[[zero:.*]] = arith.constant 0.000000e+00 : f32
  // CHECK: return %[[zero]]
  %c0_i32 = arith.constant 0 : i32
  %c16_i32 = arith.constant 16 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c0_i32, %c16_i32] : memref<4x4xf32>, i32, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @known_oob_load_index
func.func @known_oob_load_index(%arg0: memref<4xf32>) -> f32 {
  // CHECK: %[[zero:.*]] = arith.constant 0.000000e+00 : f32
  // CHECK: return %[[zero]]
  %c0_i32 = arith.constant 0 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true, indexOffset = 4 : i32} %arg0[%c0_i32] : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @known_oob_load_sgproffset
func.func @known_oob_load_sgproffset(%arg0: memref<4xf32>) -> f32 {
  // CHECK: %[[zero:.*]] = arith.constant 0.000000e+00 : f32
  // CHECK: return %[[zero]]
  %c2_i32 = arith.constant 2 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c2_i32] sgprOffset %c2_i32 : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @unknown_load
func.func @unknown_load(%arg0: memref<4xf32>, %arg1: i32) -> f32 {
  // CHECK: %[[loaded:.*]] = amdgpu.raw_buffer_load
  // CHECK: return %[[loaded]]
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%arg1] sgprOffset %c4_i32 : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @unknown_load_sgproffset
func.func @unknown_load_sgproffset(%arg0: memref<4xf32>, %arg1: i32) -> f32 {
  // CHECK: %[[loaded:.*]] = amdgpu.raw_buffer_load
  // CHECK: return %[[loaded]]
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c4_i32] sgprOffset %arg1 : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @unranked
func.func @unranked(%arg0: memref<?xf32>) -> f32 {
  // CHECK: %[[loaded:.*]] = amdgpu.raw_buffer_load
  // CHECK: return %[[loaded]]
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c4_i32] : memref<?xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @no_oob_check
func.func @no_oob_check(%arg0: memref<4xf32>) -> f32 {
  // CHECK: %[[loaded:.*]] = amdgpu.raw_buffer_load
  // CHECK: return %[[loaded]]
  %c4_i32 = arith.constant 4 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = false} %arg0[%c4_i32] : memref<4xf32>, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @in_bounds_overall
func.func @in_bounds_overall(%arg0: memref<4x4xf32>) -> f32 {
  // CHECK: %[[loaded:.*]] = amdgpu.raw_buffer_load
  // CHECK: return %[[loaded]]
  %c0_i32 = arith.constant 0 : i32
  %c15_i32 = arith.constant 15 : i32
  %0 = amdgpu.raw_buffer_load {boundsCheck = true} %arg0[%c0_i32, %c15_i32] : memref<4x4xf32>, i32, i32 -> f32
  func.return %0 : f32
}

// -----

// CHECK-LABEL: func @dead_store
func.func @dead_store(%arg0: memref<4xf32>, %arg1: f32) {
  // CHECK-NOT: amdgpu.raw_buffer_store
  %c4_i32 = arith.constant 4 : i32
  amdgpu.raw_buffer_store {boundsCheck = true} %arg1 -> %arg0[%c4_i32] : f32 -> memref<4xf32>, i32
  func.return
}

// -----

// CHECK-LABEL: func @dead_atomic_add
func.func @dead_atomic_add(%arg0: memref<4xf32>, %arg1: f32) {
  // CHECK-NOT: amdgpu.raw_buffer_atomic_fadd
  %c4_i32 = arith.constant 4 : i32
  amdgpu.raw_buffer_atomic_fadd {boundsCheck = true} %arg1 -> %arg0[%c4_i32] : f32 -> memref<4xf32>, i32
  func.return
}

// -----

// CHECK-LABEL: func @fold_gather_to_lds_of_cast
func.func @fold_gather_to_lds_of_cast(%global: memref<128x72xf32, 1>, %lds: memref<64x64xf32, 3>) {
// CHECK-SAME: %[[GLOBAL:[A-Za-z0-9]+]]: memref<128x72xf32, 1>
  %c0 = arith.constant 0 : index
  %0 = memref.cast %global : memref<128x72xf32, 1> to memref<?x?xf32, 1>
  // CHECK: amdgpu.gather_to_lds %[[GLOBAL]]
  // CHECK-SAME: : f32, memref<128x72xf32, 1>
  amdgpu.gather_to_lds %0[%c0, %c0], %lds[%c0, %c0]
    : f32, memref<?x?xf32, 1>, memref<64x64xf32, 3>
  func.return
}

// -----

// CHECK-LABEL: func @fold_gather_to_lds_of_cast_dest
func.func @fold_gather_to_lds_of_cast_dest(%global: memref<128x72xf32, 1>, %lds: memref<64x64xf32, 3>) {
// CHECK-SAME: %[[GLOBAL:[A-Za-z0-9]+]]: memref<128x72xf32, 1>
// CHECK-SAME: %[[LDS:[A-Za-z0-9]+]]: memref<64x64xf32, 3>
  %c0 = arith.constant 0 : index
  %0 = memref.cast %lds : memref<64x64xf32, 3> to memref<?x?xf32, 3>
  // CHECK: amdgpu.gather_to_lds %[[GLOBAL]][{{.*}}], %[[LDS]]
  // CHECK-SAME: : f32, memref<128x72xf32, 1>, memref<64x64xf32, 3>
  amdgpu.gather_to_lds %global[%c0, %c0], %0[%c0, %c0]
    : f32, memref<128x72xf32, 1>, memref<?x?xf32, 3>
  func.return
}
