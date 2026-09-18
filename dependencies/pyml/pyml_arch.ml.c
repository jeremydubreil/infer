#if __APPLE__
  #define PLATFORM_NAME Mac
#elif defined(WIN32) || defined(_WIN32)
  #define PLATFORM_NAME Windows
  #define WIN_HANDLE_FD
#elif unix
  #define PLATFORM_NAME Unix
#else
  #error "Unknown platform"
#endif

type t = Windows | Mac | Unix

let os = PLATFORM_NAME

#ifdef WIN_HANDLE_FD
  (* this primitive was called win_handle_fd before OCaml 5.0. Unlike the C functions in
     pyml_stubs.c, an external gets no compatibility macro: the name is resolved as a symbol at
     link time, so the pre-5.0 spelling simply does not resolve. infer builds against 5.4, hence
     the new name unconditionally. *)
  external fd_of_int : int -> Unix.file_descr = "caml_unix_filedescr_of_fd"
#else
  external fd_of_int : int -> Unix.file_descr = "%identity"
#endif
