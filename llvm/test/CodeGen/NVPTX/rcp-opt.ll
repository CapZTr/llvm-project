; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 5
; RUN: llc < %s -mtriple=nvptx64 | FileCheck %s
; RUN: %if ptxas %{ llc < %s -mtriple=nvptx64 | %ptxas-verify %}

target triple = "nvptx64-nvidia-cuda"

;; Check if fneg (fdiv 1, X) lowers to fneg (rcp.rn X).

define double @test1(double %in) {
; CHECK-LABEL: test1(
; CHECK:       {
; CHECK-NEXT:    .reg .b64 %fd<4>;
; CHECK-EMPTY:
; CHECK-NEXT:  // %bb.0:
; CHECK-NEXT:    ld.param.f64 %fd1, [test1_param_0];
; CHECK-NEXT:    rcp.rn.f64 %fd2, %fd1;
; CHECK-NEXT:    neg.f64 %fd3, %fd2;
; CHECK-NEXT:    st.param.f64 [func_retval0], %fd3;
; CHECK-NEXT:    ret;
  %div = fdiv double 1.000000e+00, %in
  %neg = fsub double -0.000000e+00, %div
  ret double %neg
}

;; Check if fdiv -1, X lowers to fneg (rcp.rn X).

define double @test2(double %in) {
; CHECK-LABEL: test2(
; CHECK:       {
; CHECK-NEXT:    .reg .b64 %fd<4>;
; CHECK-EMPTY:
; CHECK-NEXT:  // %bb.0:
; CHECK-NEXT:    ld.param.f64 %fd1, [test2_param_0];
; CHECK-NEXT:    rcp.rn.f64 %fd2, %fd1;
; CHECK-NEXT:    neg.f64 %fd3, %fd2;
; CHECK-NEXT:    st.param.f64 [func_retval0], %fd3;
; CHECK-NEXT:    ret;
  %div = fdiv double -1.000000e+00, %in
  ret double %div
}

;; Check if fdiv 1, (fneg X) lowers to fneg (rcp.rn X).

define double @test3(double %in) {
; CHECK-LABEL: test3(
; CHECK:       {
; CHECK-NEXT:    .reg .b64 %fd<4>;
; CHECK-EMPTY:
; CHECK-NEXT:  // %bb.0:
; CHECK-NEXT:    ld.param.f64 %fd1, [test3_param_0];
; CHECK-NEXT:    rcp.rn.f64 %fd2, %fd1;
; CHECK-NEXT:    neg.f64 %fd3, %fd2;
; CHECK-NEXT:    st.param.f64 [func_retval0], %fd3;
; CHECK-NEXT:    ret;
  %neg = fsub double -0.000000e+00, %in
  %div = fdiv double 1.000000e+00, %neg
  ret double %div
}
