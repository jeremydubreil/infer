(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd

module type Kind = sig
  include TaintTraceElem.Kind
end

module type S = sig
  include TaintTraceElem.S

  type spec =
    { source: t  (** type of the returned source *)
    ; index: int option  (** index of the returned source if Some; return value if None *) }
end

module Dummy : S with type t = unit
