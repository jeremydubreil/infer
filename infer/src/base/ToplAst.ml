(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd

type property_name = string [@@deriving compare, hash, sexp]

type register_name = string [@@deriving compare, equal]

type variable_name = string

type field_name = string

type class_name = string

type constant = LiteralInt of int | LiteralStr of string

type value =
  | Constant of constant
  | Register of register_name
  | Binding of variable_name
  | FieldAccess of {value: value; class_name: class_name; field_name: field_name}

type binop =
  (* all return booleans *)
  | LeadsTo
  | OpEq
  | OpNe
  | OpGe
  | OpGt
  | OpLe
  | OpLt

type predicate = Binop of binop * value * value | Value of (* bool *) value

type condition = predicate list (* conjunction *)

type assignment = register_name * variable_name

type regex = {re: (Str.regexp[@show.opaque]); re_negated: bool; re_text: string}

let mk_regex re_negated re_text = {re= Str.regexp re_text; re_negated; re_text}

type annot_pattern = {annot_negated: bool; annot_regex: regex}

type call_pattern =
  { (* [None] matches anything; i.e., does no filtering *)
    annot_pattern: annot_pattern option
  ; procedure_name_regex: regex
  ; type_regexes: regex option list option }

type label_pattern = ArrayWritePattern | CallPattern of call_pattern

(* TODO(rgrigore): Check that variable names don't repeat.  *)
(* TODO(rgrigore): Check that registers are written at most once. *)
(* INV: if [pattern] is ArrayWritePattern, then [arguments] has length 2.
    (Now ensured by parser. TODO: refactor to ensure with types.) *)
type label =
  { arguments: variable_name list option
  ; condition: condition
  ; action: assignment list
  ; pattern: label_pattern }

type vertex = string [@@deriving compare, hash, sexp, equal]

type transition =
  { source: vertex
  ; target: vertex
  ; label: label option
  ; pos_range: (Lexing.position * Lexing.position[@show.opaque]) }

(* TODO(rgrigore): Check that registers are read only after being initialized *)
type ast =
  {name: property_name; message: string option; prefixes: string list; transitions: transition list}

type t = Ast of ast | Ignored of {ignored_file: string; ignored_reason: string}
