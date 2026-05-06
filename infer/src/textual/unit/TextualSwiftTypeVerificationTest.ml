(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format
open TextualTestHelpers

(* Swift's [Double] (mangled name [TSd]) is the standard 64-bit floating-point
   type and on 64-bit platforms is what [CGFloat] is typedef'd to. The verifier
   recognizes it as compatible with [Float] in arithmetic and assignment
   contexts, the same way it does for [CGFloat] and Swift's [Float] ([TSf]). *)
let text_double_as_float =
  {|
       .source_language = "swift"
       .source_file = "fake.sil"

       declare make_double() : *__infer_swift_type<TSd>

       define returns_double_as_float() : float {
         #start:
           n0 = make_double()
           ret n0
       }
       |}


let%expect_test "Swift Double satisfies Float-typed return" =
  parse_string_and_verify_keep_going text_double_as_float ;
  [%expect
    {|
    verification succeeded - no warnings
    ------
    .source_language = "swift"

    .source_file = "fake.sil"

    declare make_double() : *__infer_swift_type<TSd>

    define returns_double_as_float() : float {
      #start:
          n0 = make_double()
          ret n0

    }


    Veryfing the transformed module...
    verification succeeded
    |}]
