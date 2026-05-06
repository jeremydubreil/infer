(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)
open! IStd

val translate_xml : string -> file_name:string -> Textual.Module.t
[@@warning "-unused-value-declaration"]
(** Parse tree-sitter XML output for a C source file and produce a Textual module. [file_name] is
    the original source file path for source location mapping. Used only by unit tests. *)

val translate_cst : TreeSitterFFI.cst_node -> file_name:string -> Textual.Module.t
(** Translate a CST node (from FFI or XML parsing) into a Textual module. *)
