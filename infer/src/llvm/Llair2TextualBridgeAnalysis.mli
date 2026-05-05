(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)
open! IStd

val find_msgsends_feeding_bridge_to_objc : Llair.func -> (int, unit) Base.Hashtbl.t
(** For a Swift LLAIR proc, return the set (keyed by [Llair.Reg.id]) of [objc_msgSend] /
    [performSelector] [areturn] registers whose result is consumed by a Swift [_bridgeToObjectiveC]
    call reachable through the local CFG.

    This is the LLAIR-level signature of an [as?] cast in Swift source: the sequence [objc_msgSend]
    -> [_unconditionallyBridgeFromObjectiveC...Sg] -> null check -> [_bridgeToObjectiveC]. Plain
    [let s = api.f()], [let s = api.f()!] and [if let s = api.f()] do not emit the trailing
    re-bridge. *)
