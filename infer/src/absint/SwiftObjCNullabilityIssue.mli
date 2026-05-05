(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd

val message : Procname.t -> string
(** Standard report message for MISSING_NULLABILITY_ANNOTATION. The message names the offending
    Objective-C method and explains why the missing annotation matters for Swift interop, so that
    static and Pulse-based reports stay consistent. *)

val should_report_at : Location.t -> bool
(** Whether a MISSING_NULLABILITY_ANNOTATION report at this location should be surfaced to the user.
    Returns [false] for bogus locations (no real line number) that the Swift frontend produces for
    some synthesized calls. *)

val is_system_framework_callee : ProcAttributes.t -> bool
(** Whether the callee was declared in a header the team can't edit -- an Apple SDK header (any path
    containing [".sdk/"]) or a prebuilt framework header ([".framework/Headers/"]). Reports against
    those declarations are unactionable noise (the team can't add [_Nullable] / [_Nonnull]
    upstream), so the checker and the Pulse model both suppress them. *)

val is_system_framework_path : string -> bool
(** Pure path predicate behind {!is_system_framework_callee}. Exposed for unit testing. *)
