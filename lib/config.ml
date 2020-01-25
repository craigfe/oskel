let pp_license ppf _ = Fmt.pf ppf "MIT"

type t = {
  name : string;
  project_synopsis : string;
  maintainer_fullname : string;
  maintainer_email : string;
  github_organisation : string;
  license : License.t;
  dependencies : string list;
  version_dune : string;
  version_ocaml : string;
  version_opam : string;
  version_ocamlformat : string;
  ocamlformat_options : (string * string) list;
  current_year : int;
  git_repo : bool;
}
