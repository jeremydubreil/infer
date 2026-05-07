; Copyright (c) Facebook, Inc. and its affiliates.
;
; This source code is licensed under the MIT license found in the
; LICENSE file in the root directory of this source tree.
;
; Hand-crafted LLVM IR exercising one of the two Swift mangled-name
; substitution patterns the Wvd parser must walk past in order to find the
; C/V class boundary marker.
;
; Pattern: substitution back-reference for a nested type.
;   "$s5Outer0A12NestedHelperC9someFieldSivpWvd"
;   After consuming "5Outer", the parser sees "0A12NestedHelper": "0" is
;   read as length=0, "A" is the back-reference letter pointing to "Outer",
;   "12NestedHelper" is the nested-type identifier. The "A" is not a digit,
;   so the parser must skip it to reach "12NestedHelper" + "C".
;
; The current .sil baseline captures the broken pre-fix behaviour: the parser
; bails on the non-digit position, so the Wvd global parses to
; (None, "unknown_field"), no class is recognised, and no
; `type __infer_swift_type<...>` declaration is injected. The follow-up
; diff in this stack adds the substitution-skip fallback to the parser and
; updates this baseline to show the recovered class type and field name.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%T5Outer0A12NestedHelperC = type { ptr, i64 }

@"$s5Outer0A12NestedHelperC9someFieldSivpWvd" = constant i64 16, align 8
