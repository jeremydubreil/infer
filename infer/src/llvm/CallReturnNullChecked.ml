(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module IdentTbl = Stdlib.Hashtbl.Make (Ident)
module PvarTbl = Stdlib.Hashtbl.Make (Pvar)
module IdentHashSet = HashSet.Make (Ident)

(* For every [Sil.Call] in the procdesc, decide whether the value it returns is later
   null-checked by the caller via a "user-handled" branch (an [if let s = e { ... }]
   with no else clause), and set [CallFlags.cf_return_null_checked = true] on the
   originating [Sil.Call] when it is. The check itself is purely syntactic on the SIL —
   we do not look at the callee's annotations here; consumers (e.g. the Swift→ObjC
   nullability checkers) apply their own annotation logic on top.

   Algorithm: a flow-insensitive may-analysis of where each [Call]'s return value
   propagates through [Load] / [Store] of local pvars. We track:
   - [id_origin]: SSA id -> the original [Call.ret_id] whose value it carries.
   - [pvar_origin]: local pvar -> the original [Call.ret_id] whose value was last stored.
   - [checked]: original [Call.ret_id] for which we saw a qualifying null check.
   We iterate over all instructions of the procdesc until none of these tables changes.
   Most procedures converge in a single pass (Calls precede Loads precede Prunes in
   typical SIL); termination is guaranteed because all three structures grow
   monotonically and are bounded by the finite number of [Ident]s and [Pvar]s in the
   procdesc. *)

let is_null_or_zero (e : Exp.t) = Exp.is_null_literal e || Exp.is_zero e

(* The Llvm frontend wraps pointer comparisons in [(int)ptr == 0] casts. *)
let rec strip_casts = function Exp.Cast (_, e) -> strip_casts e | e -> e

(* Extract [id] from a [Prune (Ne, x, 0)] / [Prune (!(Eq, x, 0))] shape, peeling casts. *)
let prune_compares_to_null (instr : Sil.instr) =
  match instr with
  | Prune (BinOp (Ne, e1, e2), _, _, _) | Prune (UnOp (LNot, BinOp (Eq, e1, e2), _), _, _, _) -> (
    match (strip_casts e1, strip_casts e2) with
    | Var id, e when is_null_or_zero e ->
        Some id
    | e, Var id when is_null_or_zero e ->
        Some id
    | _ ->
        None )
  | Prune (Var id, _, _, _) ->
      Some id
  | _ ->
      None


(* The non-null branch [Prune (Ne, x, 0)] only counts as a "real" user null check when
   its sibling eq-branch is a *trivial else* — a node with no [Store] and no [Call].
   Every other shape we observe falls outside:
   - force-unwrap [`!`] / [fatalError] -> sibling contains an aborting [Call];
   - the Llvm/Swift Optional bridge LIFT preceding the user's actual check -> sibling
     contains [Store]s to compiler-generated [__TEMP*] pvars. *)
let node_is_trivial_else node =
  Procdesc.Node.get_instrs node
  |> Instrs.for_all ~f:(fun (instr : Sil.instr) ->
         match instr with Store _ | Call _ -> false | _ -> true )


let eq_branch_is_user_safe_check node =
  match Procdesc.Node.get_preds node with
  | [pred] ->
      List.exists (Procdesc.Node.get_succs pred) ~f:(fun s ->
          (not (Procdesc.Node.equal s node)) && node_is_trivial_else s )
  | _ ->
      false


let process pdesc =
  let id_origin : Ident.t IdentTbl.t = IdentTbl.create 32 in
  let pvar_origin : Ident.t PvarTbl.t = PvarTbl.create 16 in
  let checked = IdentHashSet.create 8 in
  let visit_instr node (instr : Sil.instr) =
    match instr with
    | Call ((ret_id, _), _, _, _, _) ->
        IdentTbl.replace id_origin ret_id ret_id
    | Load {id; e= Var src} -> (
      match IdentTbl.find_opt id_origin src with
      | Some r ->
          IdentTbl.replace id_origin id r
      | None ->
          () )
    | Load {id; e= Lvar pvar} -> (
      match PvarTbl.find_opt pvar_origin pvar with
      | Some r ->
          IdentTbl.replace id_origin id r
      | None ->
          () )
    | Store {e1= Lvar pvar; e2= Var id} -> (
      match IdentTbl.find_opt id_origin id with
      | Some r ->
          PvarTbl.replace pvar_origin pvar r
      | None ->
          () )
    | Prune _ when eq_branch_is_user_safe_check node -> (
      match prune_compares_to_null instr with
      | Some id -> (
        match IdentTbl.find_opt id_origin id with
        | Some r ->
            IdentHashSet.add r checked
        | None ->
            () )
      | None ->
          () )
    | _ ->
        ()
  in
  let one_pass () =
    Procdesc.iter_nodes
      (fun node -> Procdesc.Node.get_instrs node |> Instrs.iter ~f:(visit_instr node))
      pdesc
  in
  let cardinals () =
    (IdentTbl.length id_origin, PvarTbl.length pvar_origin, IdentHashSet.length checked)
  in
  let rec loop prev =
    one_pass () ;
    let cur = cardinals () in
    if not ([%equal: int * int * int] prev cur) then loop cur
  in
  loop (-1, -1, -1) ;
  if IdentHashSet.is_empty checked then ()
  else
    let _ : bool =
      Procdesc.replace_instrs pdesc ~f:(fun _node (instr : Sil.instr) ->
          match instr with
          | Call (((ret_id, _) as ret), fexp, args, loc, flags)
            when IdentHashSet.mem checked ret_id && not flags.CallFlags.cf_return_null_checked ->
              Sil.Call (ret, fexp, args, loc, {flags with cf_return_null_checked= true})
          | _ ->
              instr )
    in
    ()
