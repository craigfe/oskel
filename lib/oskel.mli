module License = License
module Utils = Utils
module Opam = Opam

val show_errorf : ('a, Format.formatter, unit, 'b) format4 -> 'a

val run :
  project_kind:[ `Library | `Binary | `Executable ] ->
  (* These are asked for from Stdin if not supplied *)
  ?name:string ->
  ?project_synopsis:string ->
  maintainer_fullname:string option Lwt.t ->
  maintainer_email:string option Lwt.t ->
  ?github_organisation:string ->
  ?initial_version:string ->
  (* *)
  license:License.t ->
  dependencies:string list ->
  versions:Opam.versions ->
  ocamlformat_options:(string * string) list ->
  dry_run:bool ->
  non_interactive:bool ->
  git_repo:bool ->
  ?current_year:int ->
  unit ->
  unit
