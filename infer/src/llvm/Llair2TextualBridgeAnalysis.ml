(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open Llair

let is_msgsend_callee name =
  String.is_substring name ~substring:"objc_msgSend"
  || String.is_substring name ~substring:"performSelector"


let is_bridge_to_objc_callee name = String.is_substring name ~substring:"bridgeToObjectiveC"

(* Calls we're willing to walk THROUGH while looking for [_bridgeToObjectiveC]. The
   [as?]-cast lowering inserts these between the seed [objc_msgSend] and the target
   re-bridge: [_unconditionallyBridgeFromObjectiveC...Sg] for the Optional bridge,
   and the various ARC retain/release helpers. Stopping at any other call avoids
   bleeding into unrelated code that happens to share the proc. *)
let is_transparent_callee name =
  String.is_substring name ~substring:"BridgeFromObjectiveC"
  || String.is_substring name ~substring:"bridgeFromObjectiveC"
  || String.is_substring name ~substring:"objc_retain"
  || String.is_substring name ~substring:"objc_release"
  || String.is_substring name ~substring:"swift_retain"
  || String.is_substring name ~substring:"swift_release"


let callee_name (callee : Llair.callee) =
  match callee with
  | Direct {func= {name; _}; _} ->
      Some (FuncName.name name)
  | Indirect _ | Intrinsic _ ->
      None


(* Starting from [start_block], BFS forward through the local CFG. If any
   reachable block's terminator is a [Call] to a [_bridgeToObjectiveC] function,
   return [true]. Stop a branch at any non-bridge / non-transparent call so we
   stay in the tight neighborhood of the seed [objc_msgSend]. *)
let reaches_bridge_to_objc start_block =
  let visited = Hash_set.create (module String) in
  let rec visit (b : Llair.block) =
    if Hash_set.mem visited b.lbl then false
    else (
      Hash_set.add visited b.lbl ;
      match b.term with
      | Call {callee; return; _} -> (
        match callee_name callee with
        | Some name when is_bridge_to_objc_callee name ->
            true
        | Some name when is_transparent_callee name ->
            visit return.dst
        | _ ->
            false )
      | Switch {tbl; els; _} ->
          NS.IArray.exists tbl ~f:(fun (_, (jump : Llair.jump)) -> visit jump.dst) || visit els.dst
      | Iswitch {tbl; _} ->
          NS.IArray.exists tbl ~f:(fun (jump : Llair.jump) -> visit jump.dst)
      | Return _ | Throw _ | Abort _ | Unreachable _ ->
          false )
  in
  visit start_block


let find_msgsends_feeding_bridge_to_objc (func : Llair.func) =
  let result = Hashtbl.create (module Int) in
  let visited = Hash_set.create (module String) in
  let rec visit_block (b : Llair.block) =
    if not (Hash_set.mem visited b.lbl) then (
      Hash_set.add visited b.lbl ;
      ( match b.term with
      | Call {callee; areturn= Some areturn; return; _} -> (
        match callee_name callee with
        | Some name when is_msgsend_callee name ->
            if reaches_bridge_to_objc return.dst then
              Hashtbl.set result ~key:(Reg.id areturn) ~data:()
        | _ ->
            () )
      | _ ->
          () ) ;
      match b.term with
      | Switch {tbl; els; _} ->
          NS.IArray.iter tbl ~f:(fun (_, (jump : Llair.jump)) -> visit_block jump.dst) ;
          visit_block els.dst
      | Iswitch {tbl; _} ->
          NS.IArray.iter tbl ~f:(fun (jump : Llair.jump) -> visit_block jump.dst)
      | Call {return; _} ->
          visit_block return.dst
      | Return _ | Throw _ | Abort _ | Unreachable _ ->
          () )
  in
  visit_block func.entry ;
  result
