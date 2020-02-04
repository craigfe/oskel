let git_user_name () =
  match Oskel.Utils.exec "git config user.name" with
  | Ok name -> if String.(equal (trim name) "") then None else Some name
  | Error _ -> None

let git_email () =
  match Oskel.Utils.exec "git config user.email" with
  | Ok email -> if String.(equal (trim email) "") then None else Some email
  | Error _ -> None

let ( >>? ) x f = match x with Some s -> Some s | None -> f ()

let run name project_kind project_synopsis maintainer_fullname maintainer_email
    github_organisation initial_version license dependencies version_dune
    version_ocaml version_opam version_ocamlformat ocamlformat_options dry_run
    non_interactive git_repo current_year () =
  let maintainer_fullname = maintainer_fullname >>? git_user_name in
  let maintainer_email = maintainer_email >>? git_email in
  Oskel.run ?name ~project_kind ?project_synopsis ?maintainer_fullname
    ?maintainer_email ?github_organisation ?initial_version ~license
    ~dependencies ~version_dune ~version_ocaml ~version_opam
    ~version_ocamlformat ~ocamlformat_options ~dry_run ~non_interactive
    ~git_repo ?current_year ()

open Cmdliner

module Arg = struct
  include Arg

  let env_var s = env_var ("OSKEL_" ^ s)
end

let project_name = Arg.(value & pos 0 (some string) None & info ~docv:"NAME" [])

let project_kind =
  let kinds =
    [ ("library", `Library); ("binary", `Binary); ("executable", `Executable) ]
  in
  let doc =
    Fmt.str "Type of project to create. One of %s." (Arg.doc_alts_enum kinds)
  in
  let env = Arg.env_var "KIND" in
  Arg.(value & opt (enum kinds) `Library & info [ "kind" ] ~doc ~env)

let project_synopsis =
  let doc = "Synopsis of the project skeleton." in
  Arg.(value & opt (some string) None & info [ "synopsis" ] ~doc)

let maintainer_fullname =
  let doc =
    "Maintainer's full name. If not specified, Oskel will attempt to read this \
     from `git config user.name`."
  in
  let env = Arg.env_var "FULL_NAME" in
  Arg.(value & opt (some string) None & info [ "full-name" ] ~doc ~env)

let maintainer_email =
  let doc =
    "Maintainer's contact email. If not specified, Oskel will attempt to read \
     this from `git config user.email`."
  in
  let env = Arg.env_var "EMAIL" in
  Arg.(value & opt (some string) None & info [ "email" ] ~doc ~env)

let github_organisation =
  let doc = "GitHub organisation associated with the project." in
  let env = Arg.env_var "GITHUB_ORG" in
  Arg.(value & opt (some string) None & info [ "github-org" ] ~doc ~env)

let initial_version =
  let doc = "Initial version at which to release the project." in
  let env = Arg.env_var "INITIAL_VERSION" in
  Arg.(value & opt (some string) None & info [ "initial-version" ] ~doc ~env)

let license =
  let licenses = Oskel.License.all in
  let doc =
    Fmt.str "License to add to the project. One of %s."
      (Arg.doc_alts_enum licenses)
  in
  let env = Arg.env_var "LICENSE" in
  Arg.(
    value & opt (enum licenses) Oskel.License.Mit & info [ "license" ] ~doc ~env)

let dependencies =
  let doc = "Dependencies of the project in a comma-separated list." in
  let env = Arg.env_var "DEPENDS" in
  Arg.(
    value
    & opt (list ~sep:',' string) [ "fmt"; "logs" ]
    & info [ "depends" ] ~doc ~env)

let version_dune =
  let doc = "Version of dune to associate with the project." in
  let env = Arg.env_var "VERSION_DUNE" in
  Arg.(value & opt string "2.0" & info [ "version-dune" ] ~doc ~env)

let version_ocaml =
  let doc = "Version of OCaml to associate with the project." in
  let env = Arg.env_var "VERSION_OCAML" in
  Arg.(value & opt string "4.09.0" & info [ "version-ocaml" ] ~doc ~env)

let version_opam =
  let doc = "Version of opam to associate with the project." in
  let env = Arg.env_var "VERSION_DUNE" in
  Arg.(value & opt string "2.0" & info [ "version-opam" ] ~doc ~env)

let version_ocamlformat =
  let doc = "Version of OCamlformat to associate with the project." in
  let env = Arg.env_var "VERSION_OCAMLFORMAT" in
  Arg.(value & opt string "0.13.0" & info [ "version-ocamlformat" ] ~doc ~env)

let ocamlformat_options =
  let doc =
    "Options to add to the .ocamlformat file, as a comma-separated list of \
     key-value pairs. (e.g. \
     \"parse-docstrings=true,break-infix=fit-or-vertical\")"
  in
  let env = Arg.env_var "OCAMLFORMAT_OPTIONS" in
  Arg.(
    value
    & opt (list ~sep:',' (pair ~sep:'=' string string)) []
    & info [ "ocamlformat-options" ] ~doc ~env)

let dry_run =
  let doc = "Simulate the command, but don't actually perform any changes." in
  Arg.(value & flag & info [ "dry-run" ] ~doc)

let non_interactive =
  let doc = "Do not show interactive prompts." in
  Arg.(value & flag & info [ "non-interactive" ] ~doc)

let git_repo =
  let doc = "Don't generate a git repository for the project." in
  let env = Arg.env_var "DISABLE_GIT" in
  Term.(pure not $ Arg.(value & flag & info [ "disable-git" ] ~doc ~env))

let current_year =
  let doc =
    "Set the current year. Useful for achieving deterministic output."
  in
  let env = Arg.env_var "CURRENT_YEAR" in
  Arg.(value & opt (some int) None & info [ "current-year" ] ~env ~doc)

let setup_log =
  let init style_renderer level =
    Fmt_tty.setup_std_outputs ?style_renderer ();
    Logs.set_level level;
    Logs.set_reporter (Logs_fmt.reporter ())
  in
  Term.(const init $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let term =
  let doc = "Generate skeleton OCaml projects." in
  let exits = Term.default_exits in
  let man = [] in
  Term.
    ( const run
      $ project_name
      $ project_kind
      $ project_synopsis
      $ maintainer_fullname
      $ maintainer_email
      $ github_organisation
      $ initial_version
      $ license
      $ dependencies
      $ version_dune
      $ version_ocaml
      $ version_opam
      $ version_ocamlformat
      $ ocamlformat_options
      $ dry_run
      $ non_interactive
      $ git_repo
      $ current_year
      $ setup_log,
      info "oskel" ~version:"%%VERSION%%" ~doc ~exits ~man )

let () = Term.exit (Term.eval term)
