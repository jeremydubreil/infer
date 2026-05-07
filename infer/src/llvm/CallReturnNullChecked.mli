(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(** Frontend pass run by [LlvmFrontend] right after Textual→Sil for Swift modules. Sets
    [CallFlags.cf_return_null_checked] on each [Sil.Call] whose returned value is later null-checked
    by the caller in a "user-handled" branch — an [if let s = e { ... }] with no else clause —
    possibly after intervening [Load]/[Store] through a local pvar. The check is purely syntactic on
    the SIL; consumers (e.g. [SwiftObjCNullabilityChecker], the Pulse
    [PulseModelsSwift.check_missing_nullability] model) apply their own annotation logic on top to
    decide whether to suppress a missing-nullability report at the call site. *)

open! IStd

val process : Procdesc.t -> unit
