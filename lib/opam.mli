val default_opam_version : string
(** The default Opam version *)

type versions =
  (Config.versions, [ `Msg of string | `Command_not_found of string ]) result
  Lwt.t

val get_versions :
  [ `Dune of string option ] ->
  [ `OCaml of string option ] ->
  [ `Opam of string option ] ->
  [ `OCamlformat of string option ] ->
  versions
(** Given a set of versions for packages, populate any [None] values with data
    from the [opam] CLI. *)
