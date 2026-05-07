(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format

let message procname =
  F.asprintf
    "Method `%a` returns a pointer with no `_Nullable` or `_Nonnull` annotation, so Swift imports \
     it as `T!` and a `nil` result traps at the call site. Fix: annotate the Objective-C \
     declaration, or cast the result with `as?` at the Swift call site."
    Procname.pp procname


(* The Swift frontend occasionally hands us a bogus call-site location (line 0, no source position)
   for synthesized calls like implicit `init`s. Reports anchored to such locations are not
   actionable for the user, so suppress them in both the static checker and the Pulse model. *)
let should_report_at (loc : Location.t) = loc.line > 0

(* Suppress reports for callees declared in headers the team can't edit. The two signals are:

   - [".sdk/"]: the path lives inside an Xcode/Apple SDK ([iPhoneOS17.sdk/], [MacOSX14.sdk/],
     [DriverKit.sdk/], etc.). This is the high-signal Apple-framework marker.
   - [".framework/Headers/"]: a prebuilt framework's public-header layout (Apple frameworks
     unpacked outside an SDK, plus prebuilt third-party frameworks vendored under the same
     convention). Consumers can't edit those declarations either, so the suppression applies. *)
let is_system_framework_path path =
  String.is_substring path ~substring:".sdk/"
  || String.is_substring path ~substring:".framework/Headers/"


(* The callee's [translation_unit] is the .m file Clang was invoked on at capture time, not the
   header where the method was declared — so it never points at an Apple-SDK or prebuilt-framework
   path. The actual declaration site is in [attrs.loc.file], populated from the decl's source
   range; for an Apple-framework method it points at e.g.
   [.../iPhoneOS17.4.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIViewController.h],
   which is what we want to substring-match against. *)
let is_system_framework_callee (attrs : ProcAttributes.t) =
  is_system_framework_path (SourceFile.to_abs_path attrs.loc.file)
