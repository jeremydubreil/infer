(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format

let run module_ =
  PyIRTypeInference.gen_module_default_type_debug module_ ;
  PyIR.Module.pp F.std_formatter module_


let%expect_test _ =
  let source =
    {|
import dir.random
import dir.asyncio as a
from dir1.dir2.mod import x as y
from dir1.dir2 import mod

x = 0

def f(y, l):
    if y:
        g(0, y)
    else:
        for i in l:
            print(i)
        done()

async def g():
    await sleep(1)

@decofun
def h():
    pass

@decoclass
class D:
    def foo():
        pass

class C:
    def foo():
        pass

from foo import E

#type inference will currently skip E because it is imported
class B(C, D, E):
    pass
|}
  in
  PyIR.test ~run source ;
  [%expect
    {|
    type dummy = {
        y: ImportFrom[dir1.dir2.mod, x]
        mod: ImportFrom[dir1.dir2, mod]
        h: Closure[dummy.h]
        g: Closure[dummy.g]
        f: Closure[dummy.f]
        dir: Import[dir.__init__]
        a: ImportFrom[dir.__init__, asyncio]
        E: ImportFrom[foo, E]
        D: Class[D]
        C: Class[C]
        B: Class[B][C,D]
    }

    type B = {

    }

    type C = {
        foo: Closure[dummy.C.foo]
    }

    type D = {
        foo: Closure[dummy.D.foo]
    }

    module dummy:

      function toplevel():
        b0: @0
          n0 <- None @0
          jmp b1
           @0
        b1: @2
          n3 <- $ImportName(dir.random, n0, 0) @2
          TOPLEVEL[dir] <- n3 @2
          jmp b2
           @2
        b10: @20
          n14 <- $Call(n12, n13, n0) @20
          jmp b11
           @20
        b11: @21
          TOPLEVEL[h] <- n14 @21
          jmp b12
           @21
        b12: @24
          n15 <- TOPLEVEL[decoclass] @24
          jmp b13
           @24
        b13: @25
          n16 <- $MakeFunction["dummy.D", n0, n0, n0, n0] @25
          n17 <- $BuildClass(n16, "D", n0) @25
          jmp b14
           @25
        b14: @24
          n18 <- $Call(n15, n17, n0) @24
          jmp b15
           @24
        b15: @25
          TOPLEVEL[D] <- n18 @25
          jmp b16
           @25
        b16: @29
          n19 <- $MakeFunction["dummy.C", n0, n0, n0, n0] @29
          n20 <- $BuildClass(n19, "C", n0) @29
          TOPLEVEL[C] <- n20 @29
          jmp b17
           @29
        b17: @33
          n21 <- $ImportName(foo, $BuildTuple("E"), 0) @33
          n22 <- $ImportFrom(E, n21) @33
          TOPLEVEL[E] <- n22 @33
          jmp b18
           @33
        b18: @36
          n23 <- $MakeFunction["dummy.B", n0, n0, n0, n0] @36
          n24 <- TOPLEVEL[C] @36
          n25 <- TOPLEVEL[D] @36
          n26 <- TOPLEVEL[E] @36
          n27 <- $BuildClass(n23, "B", n24, n25, n26, n0) @36
          TOPLEVEL[B] <- n27 @36
          return n0
           @36
        b2: @3
          n4 <- $ImportName(dir.asyncio, n0, 0) @3
          n5 <- $ImportFrom(asyncio, n4) @3
          TOPLEVEL[a] <- n5 @3
          jmp b3
           @3
        b3: @4
          n6 <- $ImportName(dir1.dir2.mod, $BuildTuple("x"), 0) @4
          n7 <- $ImportFrom(x, n6) @4
          TOPLEVEL[y] <- n7 @4
          jmp b4
           @4
        b4: @5
          n8 <- $ImportName(dir1.dir2, $BuildTuple("mod"), 0) @5
          n9 <- $ImportFrom(mod, n8) @5
          TOPLEVEL[mod] <- n9 @5
          jmp b5
           @5
        b5: @7
          TOPLEVEL[x] <- 0 @7
          jmp b6
           @7
        b6: @9
          n10 <- $MakeFunction["dummy.f", n0, n0, n0, n0] @9
          TOPLEVEL[f] <- n10 @9
          jmp b7
           @9
        b7: @17
          n11 <- $MakeFunction["dummy.g", n0, n0, n0, n0] @17
          TOPLEVEL[g] <- n11 @17
          jmp b8
           @17
        b8: @20
          n12 <- TOPLEVEL[decofun] @20
          jmp b9
           @20
        b9: @21
          n13 <- $MakeFunction["dummy.h", n0, n0, n0, n0] @21
          jmp b10
           @21

      function dummy.B():
        b0: @36
          n0 <- None @36
          n3 <- TOPLEVEL[__name__] @36
          TOPLEVEL[__module__] <- n3 @36
          TOPLEVEL[__qualname__] <- "B" @36
          jmp b1
           @36
        b1: @37
          return n0
           @37

      function dummy.C():
        b0: @29
          n0 <- None @29
          n3 <- TOPLEVEL[__name__] @29
          TOPLEVEL[__module__] <- n3 @29
          TOPLEVEL[__qualname__] <- "C" @29
          jmp b1
           @29
        b1: @30
          n4 <- $MakeFunction["dummy.C.foo", n0, n0, n0, n0] @30
          TOPLEVEL[foo] <- n4 @30
          return n0
           @30

      function dummy.C.foo():
        b0: @30
          n0 <- None @30
          jmp b1
           @30
        b1: @31
          return n0
           @31

      function dummy.D():
        b0: @24
          n0 <- None @24
          n3 <- TOPLEVEL[__name__] @24
          TOPLEVEL[__module__] <- n3 @24
          TOPLEVEL[__qualname__] <- "D" @24
          jmp b1
           @24
        b1: @26
          n4 <- $MakeFunction["dummy.D.foo", n0, n0, n0, n0] @26
          TOPLEVEL[foo] <- n4 @26
          return n0
           @26

      function dummy.D.foo():
        b0: @26
          n0 <- None @26
          jmp b1
           @26
        b1: @27
          return n0
           @27

      function dummy.f(y, l):
        b0: @9
          n0 <- None @9
          jmp b1
           @9
        b1: @10
          n3 <- LOCAL[y] @10
          if n3 then jmp b2 else jmp b3
           @10
        b2: @11
          n13 <- GLOBAL[g] @11
          n14 <- LOCAL[y] @11
          n15 <- $Call(n13, 0, n14, n0) @11
          return n0
           @11
        b3: @13
          n4 <- LOCAL[l] @13
          n5 <- $GetIter(n4, n0) @13
          jmp b4
           @13
        b4: @13
          n6 <- $NextIter(n5, n0) @13
          n7 <- $HasNextIter(n5, n0) @13
          if n7 then jmp b5 else jmp b7
           @13
        b5: @13
          LOCAL[i] <- n6 @13
          jmp b6
           @13
        b6: @14
          n10 <- GLOBAL[print] @14
          n11 <- LOCAL[i] @14
          n12 <- $Call(n10, n11, n0) @14
          jmp b4
           @14
        b7: @13
          jmp b8
           @13
        b8: @15
          n8 <- GLOBAL[done] @15
          n9 <- $Call(n8, n0) @15
          return n0
           @15

      async function dummy.g():
        b0: @17
          n0 <- None @17
          jmp b1
           @17
        b1: @18
          n3 <- GLOBAL[sleep] @18
          n4 <- $Call(n3, 1, n0) @18
          n5 <- $GetAwaitable(n4, n0) @18
          jmp b2
           @18
        b2: @18
          jmp b4
           @18
        b4: @18
          return n0
           @18

      function dummy.h():
        b0: @20
          n0 <- None @20
          jmp b1
           @20
        b1: @22
          return n0
           @22
    |}]
