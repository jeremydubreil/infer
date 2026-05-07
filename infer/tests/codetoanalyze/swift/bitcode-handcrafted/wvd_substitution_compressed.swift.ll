; Copyright (c) Facebook, Inc. and its affiliates.
;
; This source code is licensed under the MIT license found in the
; LICENSE file in the root directory of this source tree.
;
; Hand-crafted LLVM IR exercising one of the two Swift mangled-name
; substitution patterns the Wvd parser must walk past in order to find the
; C/V class boundary marker.
;
; Pattern: substitution-compressed identifier remainder.
;   "$s8Recorder05AudioB9ViewModelC4nameSSvpWvd"
;   After consuming "8Recorder" + "05Audio", the parser sits at "B": this is
;   the suffix marker for a compressed identifier whose tail is back-referenced.
;   The parser must skip "B" to reach "9ViewModel" + "C".
;
; The current .sil baseline captures the broken pre-fix behaviour: the parser
; bails on the non-digit position, so the Wvd global parses to
; (None, "unknown_field"), no class is recognised, and no
; `type __infer_swift_type<...>` declaration is injected. The follow-up
; diff in this stack adds the substitution-skip fallback to the parser and
; updates this baseline to show the recovered class type and field name.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%T8Recorder05AudioB9ViewModelC = type { ptr, ptr }

@"$s8Recorder05AudioB9ViewModelC4nameSSvpWvd" = constant i64 8, align 8
