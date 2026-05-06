; Copyright (c) Facebook, Inc. and its affiliates.
;
; This source code is licensed under the MIT license found in the
; LICENSE file in the root directory of this source tree.
;
; Hand-crafted LLVM IR mimicking the cross-module Swift pattern that produced
; "field <class>.<prop> is not declared" consistency errors in production.
;
; Pattern: a *consumer* module has both
;   1. the LLVM struct layout for a class defined elsewhere (positional fields), and
;   2. a Wvd field-offset global naming the same class+property,
; but does NOT have the property's getter/setter declaration. The Llair2Textual
; rename pass therefore can't map field_N -> propertyName, and the Wvd-based
; field decl injection has to add the named field on top of the positional ones.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%T7Definer6ButtonC = type { ptr, i64 }

@"$s7Definer6ButtonC10tapHandleryycSgvpWvd" = constant i64 16, align 8

define void @"$s8Consumer10setHandleryy7Definer6ButtonC_yyctF"(ptr %0, i64 %1) {
entry:
  %field = getelementptr inbounds %T7Definer6ButtonC, ptr %0, i32 0, i32 1
  store i64 %1, ptr %field, align 8
  ret void
}
