; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 5
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1030 -o - < %s | FileCheck -check-prefix=CHECK %s

; The si-peephole-sdwa pass has mishandled the selections of preexisting sdwa instructions
; which led to an instruction of this shape:
;     v_lshlrev_b32_sdwa v{{[0-9]}}, v{{[0-9]}}, v{{[0-9]}} dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_1
; instead of
;     v_lshlrev_b32_sdwa v0, v1, v0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0

define amdgpu_kernel void @widget(ptr addrspace(1) %arg, i1 %arg1, ptr addrspace(3) %arg2, ptr addrspace(3) %arg3) {
; CHECK-LABEL: widget:
; CHECK:       ; %bb.0: ; %bb
; CHECK-NEXT:    s_clause 0x1
; CHECK-NEXT:    s_load_dwordx2 s[0:1], s[8:9], 0x0
; CHECK-NEXT:    s_load_dword s2, s[8:9], 0x8
; CHECK-NEXT:    s_waitcnt lgkmcnt(0)
; CHECK-NEXT:    global_load_sbyte v0, v0, s[0:1] offset:2
; CHECK-NEXT:    s_bitcmp1_b32 s2, 0
; CHECK-NEXT:    s_cselect_b32 s0, -1, 0
; CHECK-NEXT:    s_and_b32 vcc_lo, exec_lo, s0
; CHECK-NEXT:    s_cbranch_vccz .LBB0_2
; CHECK-NEXT:  ; %bb.1: ; %bb19
; CHECK-NEXT:    v_mov_b32_e32 v1, 0
; CHECK-NEXT:    ds_write_b32 v1, v1
; CHECK-NEXT:  .LBB0_2: ; %bb20
; CHECK-NEXT:    s_mov_b32 s0, exec_lo
; CHECK-NEXT:    s_waitcnt vmcnt(0)
; CHECK-NEXT:    v_cmpx_ne_u16_e32 0, v0
; CHECK-NEXT:    s_xor_b32 s0, exec_lo, s0
; CHECK-NEXT:    s_cbranch_execz .LBB0_4
; CHECK-NEXT:  ; %bb.3: ; %bb11
; CHECK-NEXT:    v_mov_b32_e32 v1, 2
; CHECK-NEXT:    v_lshlrev_b32_sdwa v0, v1, v0 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:BYTE_0
; CHECK-NEXT:    v_mov_b32_e32 v1, 0
; CHECK-NEXT:    ds_write_b32 v0, v1 offset:84
; CHECK-NEXT:  .LBB0_4: ; %bb14
; CHECK-NEXT:    s_endpgm
bb:
  %call = tail call i32 @llvm.amdgcn.workitem.id.x()
  %zext = zext i32 %call to i64
  %getelementptr = getelementptr i8, ptr addrspace(1) %arg, i64 %zext
  %load = load i8, ptr addrspace(1) %getelementptr, align 1
  %or = or disjoint i32 %call, 1
  %zext4 = zext i32 %or to i64
  %getelementptr5 = getelementptr i8, ptr addrspace(1) %arg, i64 %zext4
  %load6 = load i8, ptr addrspace(1) %getelementptr5, align 1
  %or7 = or disjoint i32 %call, 2
  %zext8 = zext i32 %or7 to i64
  %getelementptr9 = getelementptr i8, ptr addrspace(1) %arg, i64 %zext8
  %load10 = load i8, ptr addrspace(1) %getelementptr9, align 1
  br i1 %arg1, label %bb19, label %bb20

bb11:                                             ; preds = %bb20
  %zext12 = zext i8 %load10 to i64
  %getelementptr13 = getelementptr nusw [14 x i32], ptr addrspace(3) inttoptr (i32 84 to ptr addrspace(3)), i64 0, i64 %zext12
  store i32 0, ptr addrspace(3) %getelementptr13, align 4
  br label %bb14

bb14:                                             ; preds = %bb20, %bb11
  %zext15 = zext i8 %load6 to i64
  %getelementptr16 = getelementptr [14 x i32], ptr addrspace(3) %arg2, i64 0, i64 %zext15
  %zext17 = zext i8 %load to i64
  %getelementptr18 = getelementptr [14 x i32], ptr addrspace(3) %arg3, i64 0, i64 %zext17
  ret void

bb19:                                             ; preds = %bb
  store i32 0, ptr addrspace(3) null, align 4
  br label %bb20

bb20:                                             ; preds = %bb19, %bb
  %icmp = icmp eq i8 %load10, 0
  br i1 %icmp, label %bb14, label %bb11
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workitem.id.x() #0

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
