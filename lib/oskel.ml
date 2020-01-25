module License = License
module Utils = Utils

let main ~dry_run ~project_kind config =
  Logs.app (fun m -> m "%a" Fmt.(styled `Bold string) "oskel v%%VERSION%%");
  let layout =
    match project_kind with
    | `Library -> Layouts.library
    | `Binary -> Layouts.binary
    | `Executable -> Layouts.executable
  in
  Fmt.pr "@[<v>@,Creating new project:@,@,%a@]@."
    (Layouts.pp_project config)
    layout;
  if not dry_run then
    match Layouts.instantiate config layout with
    | Ok () -> ()
    | Error (`Msg msg) ->
        Fmt.epr "%s" msg;
        exit 1

let get_current_year () =
  Unix.time () |> Unix.localtime |> fun t -> t.Unix.tm_year + 1900

let run ~project ~project_kind ~project_synopsis ~maintainer_fullname
    ~maintainer_email ~github_organisation ~license ~dependencies ~version_dune
    ~version_ocaml ~version_opam ~version_ocamlformat ~ocamlformat_options
    ~dry_run ~git_repo ?(current_year = get_current_year ()) () =
  main ~project_kind ~dry_run
    {
      project;
      project_synopsis;
      maintainer_fullname;
      maintainer_email;
      github_organisation;
      license;
      dependencies;
      version_dune;
      version_ocaml;
      version_opam;
      version_ocamlformat;
      ocamlformat_options;
      current_year;
      git_repo;
    }
