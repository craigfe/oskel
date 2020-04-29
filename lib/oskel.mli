module License = License
module Utils = Utils

type versions

val default_opam_version : string

val v_versions :
  [ `Dune of string option ] ->
  [ `OCaml of string option ] ->
  [ `Opam of string option ] ->
  [ `OCamlformat of string option ] ->
  versions

val run :
  project_kind:[ `Library | `Binary | `Executable ] ->
  (* These are asked for from Stdin if not supplied *)
  ?name:string ->
  ?project_synopsis:string ->
  maintainer_fullname:string option Lwt.t ->
  maintainer_email:string option Lwt.t ->
  ?github_organisation:string ->
  ?initial_version:string ->
  license:License.t ->
  dependencies:string list ->
  versions:versions ->
  (* *)
  ocamlformat_options:(string * string) list ->
  dry_run:bool ->
  non_interactive:bool ->
  git_repo:bool ->
  ?current_year:int ->
  unit ->
  unit
