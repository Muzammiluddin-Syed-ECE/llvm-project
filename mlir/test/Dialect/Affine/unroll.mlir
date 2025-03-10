// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(func.func(affine-loop-unroll{unroll-full=true}))" | FileCheck %s --check-prefix UNROLL-FULL
// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(func.func(affine-loop-unroll{unroll-full=true unroll-full-threshold=2}))" | FileCheck %s --check-prefix SHORT
// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(func.func(affine-loop-unroll{unroll-factor=4}))" | FileCheck %s --check-prefix UNROLL-BY-4
// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(func.func(affine-loop-unroll{unroll-factor=1}))" | FileCheck %s --check-prefix UNROLL-BY-1
// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(func.func(affine-loop-unroll{unroll-factor=5 cleanup-unroll=true}))" | FileCheck %s --check-prefix UNROLL-CLEANUP-LOOP
// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="builtin.module(gpu.module(gpu.func(affine-loop-unroll{unroll-full=true})))" | FileCheck %s --check-prefix GPU-UNROLL-FULL

// UNROLL-FULL-DAG: [[$MAP0:#map[0-9]*]] = affine_map<(d0) -> (d0 + 1)>
// UNROLL-FULL-DAG: [[$MAP1:#map[0-9]*]] = affine_map<(d0) -> (d0 + 2)>
// UNROLL-FULL-DAG: [[$MAP2:#map[0-9]*]] = affine_map<(d0) -> (d0 + 3)>
// UNROLL-FULL-DAG: [[$MAP3:#map[0-9]*]] = affine_map<(d0) -> (d0 + 4)>
// UNROLL-FULL-DAG: [[$MAP4:#map[0-9]*]] = affine_map<(d0, d1) -> (d0 + 1)>
// UNROLL-FULL-DAG: [[$MAP5:#map[0-9]*]] = affine_map<(d0, d1) -> (d0 + 3)>
// UNROLL-FULL-DAG: [[$MAP6:#map[0-9]*]] = affine_map<(d0)[s0] -> (d0 + s0 + 1)>

// SHORT-DAG: [[$MAP0:#map[0-9]*]] = affine_map<(d0) -> (d0 + 1)>

// UNROLL-BY-4-DAG: [[$MAP0:#map[0-9]*]] = affine_map<(d0) -> (d0 + 1)>
// UNROLL-BY-4-DAG: [[$MAP1:#map[0-9]*]] = affine_map<(d0) -> (d0 + 2)>
// UNROLL-BY-4-DAG: [[$MAP2:#map[0-9]*]] = affine_map<(d0) -> (d0 + 3)>
// UNROLL-BY-4-DAG: [[$MAP3:#map[0-9]*]] = affine_map<(d0, d1) -> (d0 + 1)>
// UNROLL-BY-4-DAG: [[$MAP4:#map[0-9]*]] = affine_map<(d0, d1) -> (d0 + 3)>
// UNROLL-BY-4-DAG: [[$MAP5:#map[0-9]*]] = affine_map<(d0)[s0] -> (d0 + s0 + 1)>
// UNROLL-BY-4-DAG: [[$MAP6:#map[0-9]*]] = affine_map<(d0, d1) -> (d0 * 16 + d1)>
// UNROLL-BY-4-DAG: [[$MAP11:#map[0-9]*]] = affine_map<(d0) -> (d0)>

// UNROLL-FULL-LABEL: func @loop_nest_simplest() {
func.func @loop_nest_simplest() {
  // UNROLL-FULL: affine.for %arg0 = 0 to 100 step 2 {
  affine.for %i = 0 to 100 step 2 {
    // UNROLL-FULL: %c1_i32 = arith.constant 1 : i32
    // UNROLL-FULL-NEXT: %c1_i32_0 = arith.constant 1 : i32
    // UNROLL-FULL-NEXT: %c1_i32_1 = arith.constant 1 : i32
    // UNROLL-FULL-NEXT: %c1_i32_2 = arith.constant 1 : i32
    affine.for %j = 0 to 4 {
      %x = arith.constant 1 : i32
    }
  }       // UNROLL-FULL:  }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }

// UNROLL-FULL-LABEL: func @loop_nest_simple_iv_use() {
func.func @loop_nest_simple_iv_use() {
  // UNROLL-FULL: %c0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: affine.for %arg0 = 0 to 100 step 2 {
  affine.for %i = 0 to 100 step 2 {
    // UNROLL-FULL: %0 = "addi32"(%c0, %c0) : (index, index) -> i32
    // UNROLL-FULL: %1 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT:  %2 = "addi32"(%1, %1) : (index, index) -> i32
    // UNROLL-FULL: %3 = affine.apply [[$MAP1]](%c0)
    // UNROLL-FULL-NEXT:  %4 = "addi32"(%3, %3) : (index, index) -> i32
    // UNROLL-FULL: %5 = affine.apply [[$MAP2]](%c0)
    // UNROLL-FULL-NEXT:  %6 = "addi32"(%5, %5) : (index, index) -> i32
    affine.for %j = 0 to 4 {
      %x = "addi32"(%j, %j) : (index, index) -> i32
    }
  }       // UNROLL-FULL:  }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }

// Operations in the loop body have results that are used therein.
// UNROLL-FULL-LABEL: func @loop_nest_body_def_use() {
func.func @loop_nest_body_def_use() {
  // UNROLL-FULL: %c0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: affine.for %arg0 = 0 to 100 step 2 {
  affine.for %i = 0 to 100 step 2 {
    // UNROLL-FULL: %c0_0 = arith.constant 0 : index
    %c0 = arith.constant 0 : index
    // UNROLL-FULL:      %0 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %1 = "addi32"(%0, %c0_0) : (index, index) -> index
    // UNROLL-FULL-NEXT: %2 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %3 = affine.apply [[$MAP0]](%2)
    // UNROLL-FULL-NEXT: %4 = "addi32"(%3, %c0_0) : (index, index) -> index
    // UNROLL-FULL-NEXT: %5 = affine.apply [[$MAP1]](%c0)
    // UNROLL-FULL-NEXT: %6 = affine.apply [[$MAP0]](%5)
    // UNROLL-FULL-NEXT: %7 = "addi32"(%6, %c0_0) : (index, index) -> index
    // UNROLL-FULL-NEXT: %8 = affine.apply [[$MAP2]](%c0)
    // UNROLL-FULL-NEXT: %9 = affine.apply [[$MAP0]](%8)
    // UNROLL-FULL-NEXT: %10 = "addi32"(%9, %c0_0) : (index, index) -> index
    affine.for %j = 0 to 4 {
      %x = "affine.apply" (%j) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
      %y = "addi32"(%x, %c0) : (index, index) -> index
    }
  }       // UNROLL-FULL:  }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }

// UNROLL-FULL-LABEL: func @loop_nest_strided() {
func.func @loop_nest_strided() {
  // UNROLL-FULL: %c2 = arith.constant 2 : index
  // UNROLL-FULL-NEXT: %c2_0 = arith.constant 2 : index
  // UNROLL-FULL-NEXT: affine.for %arg0 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-FULL:      %0 = affine.apply [[$MAP0]](%c2_0)
    // UNROLL-FULL-NEXT: %1 = "addi32"(%0, %0) : (index, index) -> index
    // UNROLL-FULL-NEXT: %2 = affine.apply [[$MAP1]](%c2_0)
    // UNROLL-FULL-NEXT: %3 = affine.apply [[$MAP0]](%2)
    // UNROLL-FULL-NEXT: %4 = "addi32"(%3, %3) : (index, index) -> index
    affine.for %j = 2 to 6 step 2 {
      %x = "affine.apply" (%j) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
      %y = "addi32"(%x, %x) : (index, index) -> index
    }
    // UNROLL-FULL:      %5 = affine.apply [[$MAP0]](%c2)
    // UNROLL-FULL-NEXT: %6 = "addi32"(%5, %5) : (index, index) -> index
    // UNROLL-FULL-NEXT: %7 = affine.apply [[$MAP1]](%c2)
    // UNROLL-FULL-NEXT: %8 = affine.apply [[$MAP0]](%7)
    // UNROLL-FULL-NEXT: %9 = "addi32"(%8, %8) : (index, index) -> index
    // UNROLL-FULL-NEXT: %10 = affine.apply [[$MAP3]](%c2)
    // UNROLL-FULL-NEXT: %11 = affine.apply [[$MAP0]](%10)
    // UNROLL-FULL-NEXT: %12 = "addi32"(%11, %11) : (index, index) -> index
    affine.for %k = 2 to 7 step 2 {
      %z = "affine.apply" (%k) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
      %w = "addi32"(%z, %z) : (index, index) -> index
    }
  }       // UNROLL-FULL:  }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }

// UNROLL-FULL-LABEL: func @loop_nest_multiple_results() {
func.func @loop_nest_multiple_results() {
  // UNROLL-FULL: %c0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: affine.for %arg0 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-FULL: %0 = affine.apply [[$MAP4]](%arg0, %c0)
    // UNROLL-FULL-NEXT: %1 = "addi32"(%0, %0) : (index, index) -> index
    // UNROLL-FULL-NEXT: %2 = affine.apply #map{{.*}}(%arg0, %c0)
    // UNROLL-FULL-NEXT: %3:2 = "fma"(%2, %0, %0) : (index, index, index) -> (index, index)
    // UNROLL-FULL-NEXT: %4 = affine.apply #map{{.*}}(%c0)
    // UNROLL-FULL-NEXT: %5 = affine.apply #map{{.*}}(%arg0, %4)
    // UNROLL-FULL-NEXT: %6 = "addi32"(%5, %5) : (index, index) -> index
    // UNROLL-FULL-NEXT: %7 = affine.apply #map{{.*}}(%arg0, %4)
    // UNROLL-FULL-NEXT: %8:2 = "fma"(%7, %5, %5) : (index, index, index) -> (index, index)
    affine.for %j = 0 to 2 step 1 {
      %x = affine.apply affine_map<(d0, d1) -> (d0 + 1)> (%i, %j)
      %y = "addi32"(%x, %x) : (index, index) -> index
      %z = affine.apply affine_map<(d0, d1) -> (d0 + 3)> (%i, %j)
      %w:2 = "fma"(%z, %x, %x) : (index, index, index) -> (index, index)
    }
  }       // UNROLL-FULL:  }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }


// Imperfect loop nest. Unrolling innermost here yields a perfect nest.
// UNROLL-FULL-LABEL: func @loop_nest_seq_imperfect(%arg0: memref<128x128xf32>) {
func.func @loop_nest_seq_imperfect(%a : memref<128x128xf32>) {
  // UNROLL-FULL: %c0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: %c128 = arith.constant 128 : index
  %c128 = arith.constant 128 : index
  // UNROLL-FULL: affine.for %arg1 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-FULL: %0 = "vld"(%arg1) : (index) -> i32
    %ld = "vld"(%i) : (index) -> i32
    // UNROLL-FULL: %1 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %2 = "vmulf"(%c0, %1) : (index, index) -> index
    // UNROLL-FULL-NEXT: %3 = "vaddf"(%2, %2) : (index, index) -> index
    // UNROLL-FULL-NEXT: %4 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %5 = affine.apply [[$MAP0]](%4)
    // UNROLL-FULL-NEXT: %6 = "vmulf"(%4, %5) : (index, index) -> index
    // UNROLL-FULL-NEXT: %7 = "vaddf"(%6, %6) : (index, index) -> index
    // UNROLL-FULL-NEXT: %8 = affine.apply [[$MAP1]](%c0)
    // UNROLL-FULL-NEXT: %9 = affine.apply [[$MAP0]](%8)
    // UNROLL-FULL-NEXT: %10 = "vmulf"(%8, %9) : (index, index) -> index
    // UNROLL-FULL-NEXT: %11 = "vaddf"(%10, %10) : (index, index) -> index
    // UNROLL-FULL-NEXT: %12 = affine.apply [[$MAP2]](%c0)
    // UNROLL-FULL-NEXT: %13 = affine.apply [[$MAP0]](%12)
    // UNROLL-FULL-NEXT: %14 = "vmulf"(%12, %13) : (index, index) -> index
    // UNROLL-FULL-NEXT: %15 = "vaddf"(%14, %14) : (index, index) -> index
    affine.for %j = 0 to 4 {
      %x = "affine.apply" (%j) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
       %y = "vmulf"(%j, %x) : (index, index) -> index
       %z = "vaddf"(%y, %y) : (index, index) -> index
    }
    // UNROLL-FULL: %16 = "scale"(%c128, %arg1) : (index, index) -> index
    %addr = "scale"(%c128, %i) : (index, index) -> index
    // UNROLL-FULL: "vst"(%16, %arg1) : (index, index) -> ()
    "vst"(%addr, %i) : (index, index) -> ()
  }       // UNROLL-FULL }
  return  // UNROLL-FULL:  return
}

// UNROLL-FULL-LABEL: func @loop_nest_seq_multiple() {
func.func @loop_nest_seq_multiple() {
  // UNROLL-FULL: c0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: %c0_0 = arith.constant 0 : index
  // UNROLL-FULL-NEXT: %0 = affine.apply [[$MAP0]](%c0_0)
  // UNROLL-FULL-NEXT: "mul"(%0, %0) : (index, index) -> ()
  // UNROLL-FULL-NEXT: %1 = affine.apply [[$MAP0]](%c0_0)
  // UNROLL-FULL-NEXT: %2 = affine.apply [[$MAP0]](%1)
  // UNROLL-FULL-NEXT: "mul"(%2, %2) : (index, index) -> ()
  // UNROLL-FULL-NEXT: %3 = affine.apply [[$MAP1]](%c0_0)
  // UNROLL-FULL-NEXT: %4 = affine.apply [[$MAP0]](%3)
  // UNROLL-FULL-NEXT: "mul"(%4, %4) : (index, index) -> ()
  // UNROLL-FULL-NEXT: %5 = affine.apply [[$MAP2]](%c0_0)
  // UNROLL-FULL-NEXT: %6 = affine.apply [[$MAP0]](%5)
  // UNROLL-FULL-NEXT: "mul"(%6, %6) : (index, index) -> ()
  affine.for %j = 0 to 4 {
    %x = "affine.apply" (%j) { map = affine_map<(d0) -> (d0 + 1)> } :
      (index) -> (index)
    "mul"(%x, %x) : (index, index) -> ()
  }

  // UNROLL-FULL: %c99 = arith.constant 99 : index
  %k = arith.constant 99 : index
  // UNROLL-FULL: affine.for %arg0 = 0 to 100 step 2 {
  affine.for %m = 0 to 100 step 2 {
    // UNROLL-FULL: %7 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %8 = affine.apply [[$MAP6]](%c0)[%c99]
    // UNROLL-FULL-NEXT: %9 = affine.apply [[$MAP0]](%c0)
    // UNROLL-FULL-NEXT: %10 = affine.apply [[$MAP0]](%9)
    // UNROLL-FULL-NEXT: %11 = affine.apply [[$MAP6]](%9)[%c99]
    // UNROLL-FULL-NEXT: %12 = affine.apply [[$MAP1]](%c0)
    // UNROLL-FULL-NEXT: %13 = affine.apply [[$MAP0]](%12)
    // UNROLL-FULL-NEXT: %14 = affine.apply [[$MAP6]](%12)[%c99]
    // UNROLL-FULL-NEXT: %15 = affine.apply [[$MAP2]](%c0)
    // UNROLL-FULL-NEXT: %16 = affine.apply [[$MAP0]](%15)
    // UNROLL-FULL-NEXT: %17 = affine.apply [[$MAP6]](%15)[%c99]
    affine.for %n = 0 to 4 {
      %y = "affine.apply" (%n) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
      %z = "affine.apply" (%n, %k) { map = affine_map<(d0) [s0] -> (d0 + s0 + 1)> } :
        (index, index) -> (index)
    }     // UNROLL-FULL }
  }       // UNROLL-FULL }
  return  // UNROLL-FULL:  return
}         // UNROLL-FULL }

// UNROLL-FULL-LABEL: func @loop_nest_unroll_full() {
func.func @loop_nest_unroll_full() {
  // UNROLL-FULL-NEXT: %0 = "foo"() : () -> i32
  // UNROLL-FULL-NEXT: %1 = "bar"() : () -> i32
  // UNROLL-FULL-NEXT:  return
  affine.for %i = 0 to 1 {
    %x = "foo"() : () -> i32
    %y = "bar"() : () -> i32
  }
  return
} // UNROLL-FULL }

gpu.module @unroll_full {
  // GPU-UNROLL-FULL-LABEL: func @gpu_loop_nest_simplest() {
  gpu.func @gpu_loop_nest_simplest() {
    // GPU-UNROLL-FULL: affine.for %arg0 = 0 to 100 step 2 {
    affine.for %i = 0 to 100 step 2 {
      // GPU-UNROLL-FULL: %c1_i32 = arith.constant 1 : i32
      // GPU-UNROLL-FULL-NEXT: %c1_i32_0 = arith.constant 1 : i32
      // GPU-UNROLL-FULL-NEXT: %c1_i32_1 = arith.constant 1 : i32
      // GPU-UNROLL-FULL-NEXT: %c1_i32_2 = arith.constant 1 : i32
      affine.for %j = 0 to 4 {
        %x = arith.constant 1 : i32
      }
    }           // GPU-UNROLL-FULL:  }
    gpu.return  // GPU-UNROLL-FULL:  return
  }
}

// SHORT-LABEL: func @loop_nest_outer_unroll() {
func.func @loop_nest_outer_unroll() {
  // SHORT:      affine.for %arg0 = 0 to 4 {
  // SHORT-NEXT:   %0 = affine.apply [[$MAP0]](%arg0)
  // SHORT-NEXT:   %1 = "addi32"(%0, %0) : (index, index) -> index
  // SHORT-NEXT: }
  // SHORT-NEXT: affine.for %arg0 = 0 to 4 {
  // SHORT-NEXT:   %0 = affine.apply [[$MAP0]](%arg0)
  // SHORT-NEXT:   %1 = "addi32"(%0, %0) : (index, index) -> index
  // SHORT-NEXT: }
  affine.for %i = 0 to 2 {
    affine.for %j = 0 to 4 {
      %x = "affine.apply" (%j) { map = affine_map<(d0) -> (d0 + 1)> } :
        (index) -> (index)
      %y = "addi32"(%x, %x) : (index, index) -> index
    }
  }
  return  // SHORT:  return
}         // SHORT }

// We are doing a minimal FileCheck here. We just need this test case to
// successfully run. Both %x and %y will get unrolled here as the min trip
// count threshold set to 2.
// SHORT-LABEL: func @loop_nest_seq_long() -> i32 {
func.func @loop_nest_seq_long() -> i32 {
  %A = memref.alloc() : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
  %B = memref.alloc() : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
  %C = memref.alloc() : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>

  %zero = arith.constant 0 : i32
  %one = arith.constant 1 : i32
  %two = arith.constant 2 : i32

  %zero_idx = arith.constant 0 : index

  // CHECK: affine.for %arg0 = 0 to 512
  affine.for %n0 = 0 to 512 {
    // CHECK: affine.for %arg1 = 0 to 8
    affine.for %n1 = 0 to 8 {
      memref.store %one,  %A[%n0, %n1] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
      memref.store %two,  %B[%n0, %n1] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
      memref.store %zero, %C[%n0, %n1] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
    }
  }

  affine.for %x = 0 to 2 {
    affine.for %y = 0 to 2 {
      // CHECK: affine.for
      affine.for %arg2 = 0 to 8 {
        // CHECK-NOT: affine.for
        // CHECK: %{{[0-9]+}} = affine.apply
        %b2 = "affine.apply" (%y, %arg2) {map = affine_map<(d0, d1) -> (16*d0 + d1)>} : (index, index) -> index
        %z = memref.load %B[%x, %b2] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
        "op1"(%z) : (i32) -> ()
      }
      affine.for %j1 = 0 to 8 {
        affine.for %j2 = 0 to 8 {
          %a2 = "affine.apply" (%y, %j2) {map = affine_map<(d0, d1) -> (16*d0 + d1)>} : (index, index) -> index
          %v203 = memref.load %A[%j1, %a2] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
          "op2"(%v203) : (i32) -> ()
        }
        affine.for %k2 = 0 to 8 {
          %s0 = "op3"() : () -> i32
          %c2 = "affine.apply" (%x, %k2) {map = affine_map<(d0, d1) -> (16*d0 + d1)>} : (index, index) -> index
          %s1 =  memref.load %C[%j1, %c2] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
          %s2 = "addi32"(%s0, %s1) : (i32, i32) -> i32
          memref.store %s2, %C[%j1, %c2] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
        }
      }
      "op4"() : () -> ()
    }
  }
  %ret = memref.load %C[%zero_idx, %zero_idx] : memref<512 x 512 x i32, affine_map<(d0, d1) -> (d0, d1)>, 2>
  return %ret : i32
}

// UNROLL-BY-4-LABEL: func @unroll_unit_stride_no_cleanup() {
func.func @unroll_unit_stride_no_cleanup() {
  // UNROLL-BY-4: affine.for %arg0 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-BY-4: for [[L1:%arg[0-9]+]] = 0 to 8 step 4 {
    // UNROLL-BY-4-NEXT: %0 = "addi32"([[L1]], [[L1]]) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %1 = "addi32"(%0, %0) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %2 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %3 = "addi32"(%2, %2) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %4 = "addi32"(%3, %3) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %5 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %6 = "addi32"(%5, %5) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %7 = "addi32"(%6, %6) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %8 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %9 = "addi32"(%8, %8) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %10 = "addi32"(%9, %9) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: }
    affine.for %j = 0 to 8 {
      %x = "addi32"(%j, %j) : (index, index) -> i32
      %y = "addi32"(%x, %x) : (i32, i32) -> i32
    }
    // empty loop
    // UNROLL-BY-4: affine.for %arg1 = 0 to 8 {
    affine.for %k = 0 to 8 {
    }
  }
  return
}

// UNROLL-BY-4-LABEL: func @unroll_unit_stride_cleanup() {
func.func @unroll_unit_stride_cleanup() {
  // UNROLL-BY-4: affine.for %arg0 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-BY-4: for [[L1:%arg[0-9]+]] = 0 to 8 step 4 {
    // UNROLL-BY-4-NEXT:   %0 = "addi32"([[L1]], [[L1]]) : (index, index) -> i32
    // UNROLL-BY-4-NEXT:   %1 = "addi32"(%0, %0) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT:   %2 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT:   %3 = "addi32"(%2, %2) : (index, index) -> i32
    // UNROLL-BY-4-NEXT:   %4 = "addi32"(%3, %3) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT:   %5 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT:   %6 = "addi32"(%5, %5) : (index, index) -> i32
    // UNROLL-BY-4-NEXT:   %7 = "addi32"(%6, %6) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT:   %8 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT:   %9 = "addi32"(%8, %8) : (index, index) -> i32
    // UNROLL-BY-4-NEXT:   %10 = "addi32"(%9, %9) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: }
    // UNROLL-BY-4-NEXT: for [[L2:%arg[0-9]+]] = 8 to 10 {
    // UNROLL-BY-4-NEXT:   %0 = "addi32"([[L2]], [[L2]]) : (index, index) -> i32
    // UNROLL-BY-4-NEXT:   %1 = "addi32"(%0, %0) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: }
    affine.for %j = 0 to 10 {
      %x = "addi32"(%j, %j) : (index, index) -> i32
      %y = "addi32"(%x, %x) : (i32, i32) -> i32
    }
  }
  return
}

// UNROLL-BY-4-LABEL: func @unroll_non_unit_stride_cleanup() {
func.func @unroll_non_unit_stride_cleanup() {
  // UNROLL-BY-4: affine.for %arg0 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-BY-4: for [[L1:%arg[0-9]+]] = 2 to 42 step 20 {
    // UNROLL-BY-4-NEXT: %0 = "addi32"([[L1]], [[L1]]) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %1 = "addi32"(%0, %0) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %2 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %3 = "addi32"(%2, %2) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %4 = "addi32"(%3, %3) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %5 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %6 = "addi32"(%5, %5) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %7 = "addi32"(%6, %6) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: %8 = affine.apply #map{{[0-9]*}}([[L1]])
    // UNROLL-BY-4-NEXT: %9 = "addi32"(%8, %8) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %10 = "addi32"(%9, %9) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: }
    // UNROLL-BY-4-NEXT: for [[L2:%arg[0-9]+]] = 42 to 48 step 5 {
    // UNROLL-BY-4-NEXT: %0 = "addi32"([[L2]], [[L2]]) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %1 = "addi32"(%0, %0) : (i32, i32) -> i32
    // UNROLL-BY-4-NEXT: }
    affine.for %j = 2 to 48 step 5 {
      %x = "addi32"(%j, %j) : (index, index) -> i32
      %y = "addi32"(%x, %x) : (i32, i32) -> i32
    }
  }
  return
}

// Both the unrolled loop and the cleanup loop are single iteration loops.
// UNROLL-BY-4-LABEL: func @loop_nest_single_iteration_after_unroll
func.func @loop_nest_single_iteration_after_unroll(%N: index) {
  // UNROLL-BY-4: %c0 = arith.constant 0 : index
  // UNROLL-BY-4: %c4 = arith.constant 4 : index
  // UNROLL-BY-4: affine.for %arg1 = 0 to %arg0 {
  affine.for %i = 0 to %N {
    // UNROLL-BY-4: %0 = "addi32"(%c0, %c0) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %1 = affine.apply [[$MAP0]](%c0)
    // UNROLL-BY-4-NEXT: %2 = "addi32"(%1, %1) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %3 = affine.apply [[$MAP1]](%c0)
    // UNROLL-BY-4-NEXT: %4 = "addi32"(%3, %3) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %5 = affine.apply [[$MAP2]](%c0)
    // UNROLL-BY-4-NEXT: %6 = "addi32"(%5, %5) : (index, index) -> i32
    // UNROLL-BY-4-NEXT: %7 = "addi32"(%c4, %c4) : (index, index) -> i32
    // UNROLL-BY-4-NOT: for
    affine.for %j = 0 to 5 {
      %x = "addi32"(%j, %j) : (index, index) -> i32
    } // UNROLL-BY-4-NOT: }
  } // UNROLL-BY-4:  }
  return
}

// Test cases with loop bound operands.

// No cleanup will be generated here.
// UNROLL-BY-4-LABEL: func @loop_nest_operand1() {
func.func @loop_nest_operand1() {
// UNROLL-BY-4:      affine.for %arg0 = 0 to 100 step 2 {
// UNROLL-BY-4-NEXT:   affine.for %arg1 = 0 to #map{{[0-9]*}}(%arg0) step 4
// UNROLL-BY-4-NEXT:      %0 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:      %1 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:      %2 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:      %3 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:   }
// UNROLL-BY-4-NEXT: }
// UNROLL-BY-4-NEXT: return
  affine.for %i = 0 to 100 step 2 {
    affine.for %j = 0 to affine_map<(d0) -> (d0 - d0 mod 4)> (%i) {
      %x = "foo"() : () -> i32
    }
  }
  return
}

// No cleanup will be generated here.
// UNROLL-BY-4-LABEL: func @loop_nest_operand2() {
func.func @loop_nest_operand2() {
// UNROLL-BY-4:      affine.for %arg0 = 0 to 100 step 2 {
// UNROLL-BY-4-NEXT:   affine.for %arg1 = [[$MAP11]](%arg0) to #map{{[0-9]*}}(%arg0) step 4 {
// UNROLL-BY-4-NEXT:     %0 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:     %1 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:     %2 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:     %3 = "foo"() : () -> i32
// UNROLL-BY-4-NEXT:   }
// UNROLL-BY-4-NEXT: }
// UNROLL-BY-4-NEXT: return
  affine.for %i = 0 to 100 step 2 {
    affine.for %j = affine_map<(d0) -> (d0)> (%i) to affine_map<(d0) -> (5*d0 + 4)> (%i) {
      %x = "foo"() : () -> i32
    }
  }
  return
}

// UNROLL-BY-4-LABEL: func @floordiv_mod_ub
func.func @floordiv_mod_ub(%M : index, %N : index) {
  affine.for %i = 0 to %N step 4 {
    // A cleanup should be generated here.
    affine.for %j = 0 to min affine_map<(d0)[s0] -> ((16 * d0) floordiv (4 * s0))>(%i)[%N] {
      "test.foo"() : () -> ()
    }
  }
  // UNROLL-BY-4-NEXT: affine.for
  // UNROLL-BY-4-NEXT:   affine.for %{{.*}} = 0 to {{.*}} step 4
  // UNROLL-BY-4:      affine.for
  affine.for %i = 0 to %N step 4 {
    // No cleanup needed here.
    affine.for %j = 0 to min affine_map<(d0)[s0] -> ((16 * d0) mod (4 * s0))>(%i)[%N] {
      "test.foo"() : () -> ()
    }
  }
  // UNROLL-BY-4:       affine.for
  // UNROLL-BY-4-NEXT:    affine.for %{{.*}} = 0 to {{.*}} step 4
  // UNROLL-BY-4-NOT:     affine.for
  // UNROLL-BY-4:       return
    return
}

// Difference between loop bounds is constant, but not a multiple of unroll
// factor. The cleanup loop happens to be a single iteration one and is promoted.
// UNROLL-BY-4-LABEL: func @loop_nest_operand3() {
func.func @loop_nest_operand3() {
  // UNROLL-BY-4: affine.for %arg0 = 0 to 100 step 2 {
  affine.for %i = 0 to 100 step 2 {
    // UNROLL-BY-4: affine.for %arg1 = [[$MAP11]](%arg0) to #map{{[0-9]*}}(%arg0) step 4 {
    // UNROLL-BY-4-NEXT: %1 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %2 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %3 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %4 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: }
    // UNROLL-BY-4-NEXT: %0 = "foo"() : () -> i32
    affine.for %j = affine_map<(d0) -> (d0)> (%i) to affine_map<(d0) -> (d0 + 9)> (%i) {
      %x = "foo"() : () -> i32
    }
  } // UNROLL-BY-4: }
  return
}

// UNROLL-BY-4-LABEL: func @loop_nest_symbolic_bound(%arg0: index) {
func.func @loop_nest_symbolic_bound(%N : index) {
  // UNROLL-BY-4: affine.for %arg1 = 0 to 100 {
  affine.for %i = 0 to 100 {
    // UNROLL-BY-4: affine.for %arg2 = 0 to #map{{[0-9]*}}()[%arg0] step 4 {
    // UNROLL-BY-4: %0 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %1 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %2 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: %3 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: }
    // A cleanup loop will be generated here.
    // UNROLL-BY-4-NEXT: affine.for %arg2 = #map{{[0-9]*}}()[%arg0] to %arg0 {
    // UNROLL-BY-4-NEXT: %0 = "foo"() : () -> i32
    // UNROLL-BY-4-NEXT: }
    affine.for %j = 0 to %N {
      %x = "foo"() : () -> i32
    }
  }
  return
}

// UNROLL-BY-4-LABEL: func @loop_nest_symbolic_bound_with_step
// UNROLL-BY-4-SAME: %[[N:.*]]: index
func.func @loop_nest_symbolic_bound_with_step(%N : index) {
  // UNROLL-BY-4: affine.for %arg1 = 0 to 100 {
  affine.for %i = 0 to 100 {
    affine.for %j = 0 to %N step 3 {
      %x = "foo"() : () -> i32
    }
// UNROLL-BY-4:      affine.for %{{.*}} = 0 to #map{{[0-9]*}}()[%[[N]]] step 12 {
// UNROLL-BY-4:        "foo"()
// UNROLL-BY-4-NEXT:   "foo"()
// UNROLL-BY-4-NEXT:   "foo"()
// UNROLL-BY-4-NEXT:   "foo"()
// UNROLL-BY-4-NEXT: }
// A cleanup loop will be be generated here.
// UNROLL-BY-4-NEXT: affine.for %{{.*}} = #map{{[0-9]*}}()[%[[N]]] to %[[N]] step 3 {
// UNROLL-BY-4-NEXT:   "foo"()
// UNROLL-BY-4-NEXT: }
  }
  return
}

// UNROLL-BY-4-LABEL: func @loop_nest_symbolic_and_min_upper_bound
func.func @loop_nest_symbolic_and_min_upper_bound(%M : index, %N : index, %K : index) {
  affine.for %i = %M to min affine_map<()[s0, s1] -> (s0, s1, 1024)>()[%N, %K] {
    "test.foo"() : () -> ()
  }
  return
}
// No unrolling here.
// UNROLL-BY-4:      affine.for %{{.*}} = %{{.*}} to min #map{{.*}}()[%{{.*}}, %{{.*}}] {
// UNROLL-BY-4-NEXT:   "test.foo"() : () -> ()
// UNROLL-BY-4-NEXT: }
// UNROLL-BY-4-NEXT: return

// The trip count here is a multiple of four, but this can be inferred only
// through composition. Check for no cleanup scf.
// UNROLL-BY-4-LABEL: func @loop_nest_non_trivial_multiple_upper_bound
func.func @loop_nest_non_trivial_multiple_upper_bound(%M : index, %N : index) {
  %T = affine.apply affine_map<(d0) -> (4*d0 + 1)>(%M)
  %K = affine.apply affine_map<(d0) -> (d0 - 1)> (%T)
  affine.for %i = 0 to min affine_map<(d0, d1) -> (4 * d0, d1, 1024)>(%N, %K) {
    "foo"() : () -> ()
  }
  return
}
// UNROLL-BY-4: affine.for %arg2 = 0 to min
// UNROLL-BY-4-NOT: for
// UNROLL-BY-4: return

// UNROLL-BY-4-LABEL: func @multi_upper_bound
func.func @multi_upper_bound(%arg0: index) {
  affine.for %i = 0 to min affine_map<()[s0] -> (8 * s0, 12 * s0)>()[%arg0] {
    "test.foo"() : () -> ()
  }
  // No unrolling possible here.
  // UNROLL-BY-4: affine.for %{{.*}} = 0 to min #map{{.*}}()[%{{.*}}]
  return
}

// UNROLL-BY-4-LABEL: func @multi_lower_bound
func.func @multi_lower_bound(%arg0: index) {
  affine.for %i = max affine_map<()[s0] -> (8 * s0, 12 * s0)>()[%arg0] to 100 {
    "test.foo"() : () -> ()
  }
  // TODO: Extend getTripCountMapAndOperands to handle multi-result lower bound
  // maps.
  // UNROLL-BY-4: affine.for %{{.*}} = max #map{{.*}}()[%{{.*}}] to 100
  // UNROLL-BY-4-NOT: affine.for
  return
}

// UNROLL-BY-4-LABEL: func @loop_nest_non_trivial_multiple_upper_bound_alt
func.func @loop_nest_non_trivial_multiple_upper_bound_alt(%M : index, %N : index) {
  %K = affine.apply affine_map<(d0) -> (4*d0)> (%M)
  affine.for %i = 0 to min affine_map<()[s0, s1] -> (4 * s0, s1, 1024)>()[%N, %K] {
    "foo"() : () -> ()
  }
  // UNROLL-BY-4: affine.for %arg2 = 0 to min
  // UNROLL-BY-4-NEXT: "foo"
  // UNROLL-BY-4-NEXT: "foo"
  // UNROLL-BY-4-NEXT: "foo"
  // UNROLL-BY-4-NEXT: "foo"
  // UNROLL-BY-4-NOT: for
  // UNROLL-BY-4: return
  return
}

// UNROLL-BY-1-LABEL: func @unroll_by_one_should_promote_single_iteration_loop()
func.func @unroll_by_one_should_promote_single_iteration_loop() {
  affine.for %i = 0 to 1 {
    %x = "foo"(%i) : (index) -> i32
  }
  return
// UNROLL-BY-1-NEXT: %c0 = arith.constant 0 : index
// UNROLL-BY-1-NEXT: %0 = "foo"(%c0) : (index) -> i32
// UNROLL-BY-1-NEXT: return
}

// Test unrolling with affine.for iter_args.

// UNROLL-BY-4-LABEL: loop_unroll_with_iter_args_and_cleanup
func.func @loop_unroll_with_iter_args_and_cleanup(%arg0 : f32, %arg1 : f32, %n : index) -> (f32,f32) {
  %cf1 = arith.constant 1.0 : f32
  %cf2 = arith.constant 2.0 : f32
  %sum:2 = affine.for %iv = 0 to 10 iter_args(%i0 = %arg0, %i1 = %arg1) -> (f32, f32) {
    %sum0 = arith.addf %i0, %cf1 : f32
    %sum1 = arith.addf %i1, %cf2 : f32
    affine.yield %sum0, %sum1 : f32, f32
  }
  return %sum#0, %sum#1 : f32, f32
  // UNROLL-BY-4:      %[[SUM:.*]]:2 = affine.for {{.*}} = 0 to 8 step 4 iter_args
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   arith.addf
  // UNROLL-BY-4-NEXT:   %[[Y1:.*]] = arith.addf
  // UNROLL-BY-4-NEXT:   %[[Y2:.*]] = arith.addf
  // UNROLL-BY-4-NEXT:   affine.yield %[[Y1]], %[[Y2]]
  // UNROLL-BY-4-NEXT: }
  // UNROLL-BY-4-NEXT: %[[SUM1:.*]]:2 = affine.for {{.*}} = 8 to 10 iter_args(%[[V1:.*]] = %[[SUM]]#0, %[[V2:.*]] = %[[SUM]]#1)
  // UNROLL-BY-4:      }
  // UNROLL-BY-4-NEXT: return %[[SUM1]]#0, %[[SUM1]]#1
}

// The epilogue being a single iteration loop gets promoted here.

// UNROLL-BY-4-LABEL: unroll_with_iter_args_and_promotion
func.func @unroll_with_iter_args_and_promotion(%arg0 : f32, %arg1 : f32) -> f32 {
  %from = arith.constant 0 : index
  %to = arith.constant 10 : index
  %step = arith.constant 1 : index
  %sum = affine.for %iv = 0 to 9 iter_args(%sum_iter = %arg0) -> (f32) {
    %next = arith.addf %sum_iter, %arg1 : f32
    affine.yield %next : f32
  }
  // UNROLL-BY-4:      %[[SUM:.*]] = affine.for %{{.*}} = 0 to 8 step 4 iter_args(%[[V0:.*]] =
  // UNROLL-BY-4-NEXT:   %[[V1:.*]] = arith.addf %[[V0]]
  // UNROLL-BY-4-NEXT:   %[[V2:.*]] = arith.addf %[[V1]]
  // UNROLL-BY-4-NEXT:   %[[V3:.*]] = arith.addf %[[V2]]
  // UNROLL-BY-4-NEXT:   %[[V4:.*]] = arith.addf %[[V3]]
  // UNROLL-BY-4-NEXT:   affine.yield %[[V4]]
  // UNROLL-BY-4-NEXT: }
  // UNROLL-BY-4-NEXT: %[[RES:.*]] = arith.addf %[[SUM]],
  // UNROLL-BY-4-NEXT: return %[[RES]]
  return %sum : f32
}

// UNROLL-FULL: func @unroll_zero_trip_count_case
func.func @unroll_zero_trip_count_case() {
  // CHECK-NEXT: affine.for %{{.*}} = 0 to 0
  affine.for %i = 0 to 0 {
  }
  return
}

// UNROLL-CLEANUP-LOOP-LABEL: func @unroll_cleanup_loop_with_larger_unroll_factor()
func.func @unroll_cleanup_loop_with_larger_unroll_factor() {
  affine.for %i = 0 to 3 {
    %x = "foo"(%i) : (index) -> i32
  }
  return
// UNROLL-CLEANUP-LOOP-NEXT: %[[C0:.*]] = arith.constant 0 : index
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[C0]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V1:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V1]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V2:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V2]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: return
}

// UNROLL-CLEANUP-LOOP-LABEL: func @unroll_cleanup_loop_with_smaller_unroll_factor()
func.func @unroll_cleanup_loop_with_smaller_unroll_factor() {
  affine.for %i = 0 to 7 {
    %x = "foo"(%i) : (index) -> i32
  }
  return
// UNROLL-CLEANUP-LOOP-NEXT: %[[C0:.*]] = arith.constant 0 : index
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[C0]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V1:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V1]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V2:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V2]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V3:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V3]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V4:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V4]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V5:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V5]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V6:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V6]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: return
}

// UNROLL-CLEANUP-LOOP-LABEL: func @unroll_cleanup_loop_with_identical_unroll_factor()
func.func @unroll_cleanup_loop_with_identical_unroll_factor() {
  affine.for %i = 0 to 5 {
    %x = "foo"(%i) : (index) -> i32
  }
  return
// UNROLL-CLEANUP-LOOP-NEXT: %[[C0:.*]] = arith.constant 0 : index
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[C0]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V1:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V1]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V2:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V2]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V3:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V3]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: %[[V4:.*]] = affine.apply {{.*}}
// UNROLL-CLEANUP-LOOP-NEXT: {{.*}} = "foo"(%[[V4]]) : (index) -> i32
// UNROLL-CLEANUP-LOOP-NEXT: return
}

// UNROLL-BY-4-LABEL: func @known_multiple_ceildiv
func.func @known_multiple_ceildiv(%N: index, %S: index) {
  %cst = arith.constant 0.0 : f32
  %m = memref.alloc(%S) : memref<?xf32>
  // This exercises affine expr getLargestKnownDivisor for the ceildiv case.
  affine.for %i = 0 to affine_map<(d0) -> (32 * d0 + 64)>(%N) step 8 {
    affine.store %cst, %m[%i] : memref<?xf32>
  }
  // UNROLL-BY-4:     affine.for %{{.*}} = 0 to {{.*}} step 32
  // UNROLL-BY-4-NOT: affine.for

  // This exercises affine expr getLargestKnownDivisor for floordiv.
  affine.for %i = 0 to affine_map<(d0) -> ((32 * d0 + 64) floordiv 8)>(%N) {
    affine.store %cst, %m[%i] : memref<?xf32>
  }
  // UNROLL-BY-4:     affine.for %{{.*}} = 0 to {{.*}} step 4
  // UNROLL-BY-4-NOT: affine.for
  // UNROLL-BY-4:     return
  return
}
