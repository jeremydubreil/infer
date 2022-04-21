(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format

(** Names for fields of class/struct/union *)
type t [@@deriving compare, equal, yojson_of]

val loose_compare : t -> t -> int
(** Similar to compare, but addresses [CStruct x] and [CppClass x] as equal. *)

val compare_name : t -> t -> int
(** Similar to compare, but compares only names, except template arguments. *)

val make : Typ.Name.t -> string -> t
(** create a field of the given class and fieldname *)

val get_class_name : t -> Typ.Name.t

val get_field_name : t -> string

val mk_fake_capture_field : id:int -> Typ.t -> CapturedVar.capture_mode -> t

val is_fake_capture_field : t -> bool

val is_fake_capture_field_weak : t -> bool

val is_fake_capture_field_by_ref : t -> bool

val get_capture_field_position : t -> int option

val is_java : t -> bool

val is_java_synthetic : t -> bool
(** Check if the field is autogenerated/synthetic **)

val is_internal : t -> bool
(** Check if the field has the prefix "__" or "_M_" (internal field of std::thread::id) *)

(** Set for fieldnames *)
module Set : Caml.Set.S with type elt = t

(** Map for fieldnames *)
module Map : PrettyPrintable.PPMap with type key = t

val is_java_outer_instance : t -> bool
(** Check if the field is the synthetic this$n of a nested class, used to access the n-th outer
    instance. *)

val to_string : t -> string
(** Convert a field name to a string. *)

val to_full_string : t -> string

val to_simplified_string : t -> string
(** Convert a fieldname to a simplified string with at most one-level path. For example,

    - In C++: "<ClassName>::<FieldName>"
    - In Java, ObjC, C#: "<ClassName>.<FieldName>"
    - In C: "<StructName>.<FieldName>" or "<UnionName>.<FieldName>"
    - In Erlang: "<FieldName>" *)

val patterns_match : Re.Str.regexp list -> t -> bool
(** Test whether a field full string matches to one of the regular expressions. *)

val pp : F.formatter -> t -> unit
(** Pretty print a field name. *)

module Normalizer : HashNormalizer.S with type t = t
