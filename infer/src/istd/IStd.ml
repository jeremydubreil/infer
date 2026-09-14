(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

include Core
module Unix = UnixLabels

[@@@warning "-unused-value-declaration"]

(* easy access to sub-module *)
module DLS = struct
  include Domain.DLS

  let incr key = get key |> (fun x -> x + 1) |> set key

  let decr key = get key |> (fun x -> x - 1) |> set key
end

(* Compare police: generic compare mostly disabled. *)
let compare = No_polymorphic_compare.compare

let equal = No_polymorphic_compare.equal

let ( = ) = No_polymorphic_compare.( = )

let failwith _ : [`use_Logging_die_instead] = assert false

let failwithf _ : [`use_Logging_die_instead] = assert false

let invalid_arg _ : [`use_Logging_die_instead] = assert false

let invalid_argf _ : [`use_Logging_die_instead] = assert false

let exit = `In_general_prefer_using_Logging_exit_over_Pervasives_exit

[@@@warning "+unused-value-declaration"]

module ANSITerminal : module type of ANSITerminal = struct
  include ANSITerminal

  (* more careful about when the channel is connected to a tty *)

  let print_string = if Unix.(isatty stdout) then print_string else fun _ -> Stdlib.print_string

  let prerr_string = if Unix.(isatty stderr) then prerr_string else fun _ -> Stdlib.prerr_string

  let printf styles fmt = Format.ksprintf (fun s -> print_string styles s) fmt

  let eprintf styles fmt = Format.ksprintf (fun s -> prerr_string styles s) fmt

  let sprintf = if Unix.(isatty stderr) then sprintf else fun _ -> Printf.sprintf
end

(* HACK to make the deadcode script record dependencies on [HashNormalizer]: the "normalize" ppx in
   inferppx generates code that refers to [HashNormalizer] but that dependency is invisible to
   [ocamldep], which runs before ppx expansion. This way any file that depends on [IStd]
   automatically depends on [HashNormalizer], which is enough for now. *)
module _ = HashNormalizer

(* TEMPORARY: with INFER_MEMPROF=<n> set, print the OCaml call stack of every [n]th sampled
   allocation. This lives in IStd so that it is installed before any other module of infer is
   initialised: gdb cannot unwind OCaml frames on Windows and a Gc alarm needs a major cycle to
   complete, but a memprof callback runs on the allocating stack itself. *)
let () =
  match Stdlib.Sys.getenv_opt "INFER_MEMPROF" with
  | None ->
      ()
  | Some every ->
      let every = Option.value (Stdlib.int_of_string_opt every) ~default:200 in
      let samples = ref 0 in
      let sample : Stdlib.Gc.Memprof.allocation -> unit option =
       fun alloc ->
        Stdlib.incr samples ;
        if Int.equal (Int.rem !samples every) 0 then
          Stdlib.Printf.eprintf "MEMPROF sample=%d size=%d\n%s\n%!" !samples alloc.size
            (Stdlib.Printexc.raw_backtrace_to_string alloc.callstack) ;
        None
      in
      ignore
        (Stdlib.Gc.Memprof.start ~sampling_rate:1e-4 ~callstack_size:25
           {Stdlib.Gc.Memprof.null_tracker with alloc_minor= sample; alloc_major= sample} )
