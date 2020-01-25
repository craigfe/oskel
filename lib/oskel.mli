module License = License
module Utils = Utils

val run :
  project:string ->
  project_kind:[ `Library | `Binary | `Executable ] ->
  project_synopsis:string ->
  maintainer_fullname:string ->
  maintainer_email:string ->
  github_organisation:string ->
  license:License.t ->
  dependencies:string list ->
  version_dune:string ->
  version_ocaml:string ->
  version_opam:string ->
  version_ocamlformat:string ->
  ocamlformat_options:(string * string) list ->
  dry_run:bool ->
  git_repo:bool ->
  ?current_year:int ->
  unit ->
  unit
