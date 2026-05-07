; Copyright (c) Facebook, Inc. and its affiliates.
;
; This source code is licensed under the MIT license found in the
; LICENSE file in the root directory of this source tree.
;
; Hand-crafted LLVM IR pinning the [GetElementPtr (StaticByteOffset n)]
; path: a [getelementptr i8, ptr %nav, i64 N] with [N] a literal
; compile-time constant (no [Wvd]-load), targeting an inline
; existential-container store of [self] into the receiver's [delegate]
; field.
;
; Production motivation. This shape is the constant-folded variant of
; [receiver.delegate = self] that swift -O emits when the optimiser
; sees a [Wvd] descriptor with a known constant initialiser and folds
; the runtime [load Wvd] into a literal [i64 N] in the GEP. The
; runtime-loaded variant ([getelementptr i8, ptr %nav, i64 %wvd]) is
; handled separately by the [DynamicWvd] path
; ([Llair2TextualField.extract_class_and_field_from_wvd] +
; D104039809's substitution-mangling support); this case is handled by
; [LlvmSledgeFrontend] emitting [GetElementPtr (StaticByteOffset n)]
; and [Llair2Textual] resolving [n] to a typed field via
; [Llair2TextualField.lookup_field_by_byte_offset]'s byte-cursor walk
; through the receiver's declared fields.
;
; What this file pins. With this diff applied, the SIL store target
; is the typed Field [n8.delegate] (receiver chain preserved).
; Without it, the [Some _n -> Llair.Exp.nondet] fallback in
; [LlvmSledgeFrontend.GetElementPtr] case 3 collapses the GEP
; destination to [_fun_llvm_nondet()] and Pulse loses the
; [self -> nav -> delegate -> self] receiver chain.
;
; Verified empirically: on origin/master (without this diff), running
; [make capture] on this same .ll produces
;   store $builtins.llvm_nondet() <- n9
; in place of the typed Field store recorded in the [.sil] baseline.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Receiver class layout: 16-byte Swift class header (metadata + refcount)
; followed by a single [ptr] user field at byte offset 16.
%T4Test10NavbarViewC = type { ptr, ptr, ptr }

; Wvd field-offset descriptor for the [delegate] field at byte 16.
; Its presence (handled by [Llair2Textual.DynamicWvd]) injects a
; typed [delegate] field declaration into the struct in the type env,
; which the [StaticByteOffset]'s byte-cursor walk needs in order to
; resolve a constant byte offset to a typed field. The GEP itself
; uses a literal constant offset (not a Wvd-load) — that's what
; exercises the [StaticByteOffset] path being pinned here.
@"$s4Test10NavbarViewC8delegateAA0bC8Delegate_pSgvpWvd" = constant i64 16, align 8

%swift.metadata_response = type { ptr, i64 }

; The [Ma] metadata accessor for the receiver class. The
; [Llair2TextualTypeInference] pre-pass uses this to tag the
; [swift_allocObject] result with the concrete Swift class type.
declare swiftcc %swift.metadata_response @"$s4Test10NavbarViewCMa"(i64) #0

declare ptr @swift_allocObject(ptr, i64, i64) #0

define ptr @"$s4Test14ViewControllerC10navbarViewAA0c6NavbarF0CvgAGyXEfU_"(ptr %self) {
entry:
  ; nav = NavbarView()
  %m_resp = call swiftcc %swift.metadata_response @"$s4Test10NavbarViewCMa"(i64 0)
  %m = extractvalue %swift.metadata_response %m_resp, 0
  %nav = call ptr @swift_allocObject(ptr %m, i64 24, i64 7)

  ; nav.delegate = self
  ; Literal constant byte offset (no Wvd-load); 16 = end of Swift
  ; class header, i.e. the byte offset of the first declared user field.
  %slot = getelementptr i8, ptr %nav, i64 16
  store ptr %self, ptr %slot, align 8

  ret ptr %nav
}

attributes #0 = { nounwind }
