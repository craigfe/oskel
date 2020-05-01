let pp_license ppf _ = Fmt.pf ppf "MIT"

type versions = {
  dune : string;
  ocaml : string;
  opam : string;
  ocamlformat : string;
}

type t = {
  name : string;
  project_synopsis : string;
  maintainer_fullname : string;
  maintainer_email : string;
  github_organisation : string;
  initial_version : string;
  license : License.t;
  dependencies : string list;
  versions : versions;
  ocamlformat_options : (string * string) list;
  current_year : int;
  git_repo : bool;
}
