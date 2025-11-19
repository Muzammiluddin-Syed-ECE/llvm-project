# WMMA Scales Implementation - Complete

## Summary
Successfully added scaled WMMA intrinsics for gfx1250+, rebased onto latest upstream/main.

## Changes Made

### 1. ROCDLOps.td
- Created `ROCDL_WMMA_Scale_IntrOp` class for scaled WMMA intrinsics with format parameters (f8f6f4 variant)
- Created `ROCDL_WMMA_Scale_F4_IntrOp` class for FP4 variant (no format parameters)
- Added comprehensive documentation for both classes following LLVM coding standards
- Updated intrinsic definitions:
  - `ROCDL_wmma_scale_f32_16x16x128_f8f6f4`
  - `ROCDL_wmma_scale16_f32_16x16x128_f8f6f4`
  - `ROCDL_wmma_scale_f32_32x16x128_f4`
  - `ROCDL_wmma_scale16_f32_32x16x128_f4`

## Key Technical Decisions

### Attribute vs Operand Parameters
Following the refactoring pattern in PR #167041:
- **Attributes** (compile-time constants):
  - `matrix_a_fmt`, `matrix_b_fmt` (format selection)
  - `modC` (matrix C modifier)
  - `matrix_a_scale`, `matrix_b_scale` (scale modes)
  - `matrix_a_scale_fmt`, `matrix_b_scale_fmt` (scale formats)
  - `reuseA`, `reuseB` (reuse flags)

- **Operands** (runtime values):
  - `A`, `B`, `C` (matrix data)
  - `matrix_a_scale_exp`, `matrix_b_scale_exp` (scale exponents)

### Overloaded Operands - THE FIX
**Critical Discovery**: The `overloadedOperands` parameter in `ROCDL_IntrOp` refers to **LLVM intrinsic parameter positions**, not MLIR operand positions!

- **F8F6F4 variant**: `[1, 3]` - A is at LLVM parameter position 1, B at position 3
  - LLVM signature: `(i32 fmt_a, vecA, i32 fmt_b, vecB, i16 modC, ...)`
  - Position 1 = vecA, Position 3 = vecB
  
- **F4 variant**: `[0, 1]` - A is at LLVM parameter position 0, B at position 1
  - LLVM signature: `(vecA, vecB, i16 modC, ...)`
  - Position 0 = vecA, Position 1 = vecB

This allows LLVM to properly mangle the intrinsic name based on the actual vector types of A and B, supporting different combinations like:
- `v16i32` x `v16i32` (FP8 x FP8)
- `v16i32` x `v12i32` (FP8 x FP6)
- `v16i32` x `v8i32` (FP8 x FP4)

### ImmArg Positions
The immediate argument positions in the LLVM intrinsic:
- F8F6F4 variant: `[0, 2, 4, 6, 7, 9, 10, 12, 13]`
- F4 variant: `[2, 4, 5, 7, 8, 10, 11]`

## Status: ✅ Complete

### ✅ Working
- TableGen definitions compile successfully
- Single wmma.scale operations translate correctly to LLVM IR
- **Multiple wmma.scale operations in the same function work correctly**
- Correct intrinsic mangling for different operand types
- All variants (f8f6f4 and f4, scale and scale16) work individually and in combination
- Successfully rebased onto latest upstream/main

### Test Results
```mlir
// Multiple operations - NOW WORKS!
%r00 = rocdl.wmma.scale.f32.16x16x128.f8f6f4 %arg5, %arg5, %arg1, %arg0, %arg0 {...}
%r01 = rocdl.wmma.scale.f32.16x16x128.f8f6f4 %arg5, %arg5, %arg1, %arg0, %arg0 {...}
// Both calls succeed and generate correct LLVM IR
```

## Testing
```bash
cd ~/iree/third_party/llvm-project-wmma-scales-update/build

# Rebuild
ninja MLIRROCDLOpsIncGen MLIRROCDLToLLVMIRTranslation mlir-translate

# Test single operation
bin/mlir-translate -mlir-to-llvmir /tmp/test_wmma_scale.mlir

# Test multiple operations
bin/mlir-translate -mlir-to-llvmir /tmp/test_two_scales.mlir

# Test f4 variant
bin/mlir-translate -mlir-to-llvmir /tmp/test_f4_fixed.mlir
```

## References
- PR #165915: Original scaled WMMA intrinsics (being updated)
- PR #167041: WMMA intrinsic refactoring (operands → attributes)
- `llvm/include/llvm/IR/IntrinsicsAMDGPU.td`: LLVM intrinsic definitions
- Upstream commit: `6f8e87b9d097` (rebased onto)

## Branch
- Worktree: `~/iree/third_party/llvm-project-wmma-scales-update`
- Branch: `muzasyed/wmmaScales-rebased` (rebased onto upstream/main)
- Commit: `7725b23eff80`
