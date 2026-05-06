(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format
module CC = CongruenceClosureSolver

module Var : sig
  type t = private string [@@deriving compare, equal]

  val pp : F.formatter -> t -> unit

  val of_string : string -> t

  module Map : Stdlib.Map.S with type key = t

  module Set : Stdlib.Set.S with type elt = t
end

type subst

val pp_subst : CC.t -> F.formatter -> subst -> unit
[@@warning "-unused-value-declaration"]
(** used only by unit tests *)

val mk_subst : (Var.t * CC.Atom.t) list -> subst
[@@warning "-unused-value-declaration"]
(** used only by unit tests *)

module Pattern : sig
  type t = Var of Var.t | Term of {header: CC.header; args: t list}

  type ellipsis = {header: CC.header; arg: t}

  val pp : F.formatter -> t -> unit
  [@@warning "-unused-value-declaration"]
  (** used only by unit tests *)

  val pp_ellipsis : F.formatter -> ellipsis -> unit
  [@@warning "-unused-value-declaration"]
  (** used only by unit tests *)

  val vars : t -> Var.t list
end

module Rule : sig
  type t =
    | Regular of {lhs: Pattern.t; rhs: Pattern.t; exclude: CC.Atom.t list; mutable fire_count: int}
    | Ellipsis of {ellipsis: Pattern.ellipsis; mutable fire_count: int}

  val pp : F.formatter -> t -> unit

  val fire_count : t -> int

  exception FuelExhausted of {round_count: int}

  val full_rewrite : ?debug:bool -> ?fuel:int -> CC.t -> t list -> int
  (** iterate rewriting until saturation.
      @raise FuelExhausted if fuel exhausted before saturation *)
end

val e_match_pattern_at : ?debug:bool -> CC.t -> Pattern.t -> CC.Atom.t -> subst list
[@@warning "-unused-value-declaration"]
(** Match a pattern against a specific atom. Returns all valid substitutions. Used only by unit
    tests. *)

val subst_find : subst -> Var.t -> CC.Atom.t option
(** Look up a variable binding in a substitution. *)

type parse_error

val pp_parse_error : F.formatter -> parse_error -> unit

val parse_pattern : CC.t -> string -> (Pattern.t, parse_error) result

val parse_rule : CC.t -> string -> (Rule.t, parse_error) result

[@@@warning "-unused-module"]

(** [@@@warning "-unused-module"] above suppresses warnings: this whole module is for tests only *)
module TestOnly : sig
  val e_match_pattern_at : ?debug:bool -> CC.t -> Pattern.t -> CC.Atom.t -> subst list
  [@@warning "-unused-value-declaration"]

  val e_match_pattern : ?debug:bool -> CC.t -> Pattern.t -> f:(CC.Atom.t -> subst -> unit) -> unit
  [@@warning "-unused-value-declaration"]

  val e_match_ellipsis_at : CC.t -> Pattern.ellipsis -> CC.Atom.t -> CC.Atom.t list
  [@@warning "-unused-value-declaration"]

  val pattern_to_term : CC.t -> subst -> Pattern.t -> CC.Atom.t
  [@@warning "-unused-value-declaration"]

  val apply_rule_at : ?debug:bool -> CC.t -> Rule.t -> CC.Atom.t -> int
  [@@warning "-unused-value-declaration"]
  (** return the number of compatible substitution used during rewriting *)

  val rewrite_rules_once : ?debug:bool -> CC.t -> Rule.t list -> int
  [@@warning "-unused-value-declaration"]
end
