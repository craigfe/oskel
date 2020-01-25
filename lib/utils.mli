val exec : string -> (string, [ `Msg of string ]) result

val sequence_commands : string list -> (unit, [ `Msg of string ]) result

val print_to_file : string -> (Format.formatter -> unit) -> unit

val mkdir_p : string -> unit

val file_of_project : string -> string
(** Given an opam package name, derive a conventional name for the top-level
    file name. Replaces all '-' characters with '_'. *)

val findlib_of_project : string -> string
(** Like {!file_of_project} but capitalised. *)
