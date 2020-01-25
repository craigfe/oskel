module License = License
module Utils = Utils

let main ~dry_run ~project_kind config =
  let project = Layouts.project_of_kind project_kind in
  Logs.app (fun m -> m "@[<v>@,%a@]" (Layouts.pp_project config) project);
  if not dry_run then
    match Layouts.instantiate config project with
    | Ok () ->
        Logs.app (fun m ->
            m "%a Created new project" Fmt.(styled `Green string) "success")
    | Error (`Msg msg) ->
        Fmt.epr "%s" msg;
        exit 1

let get_current_year () =
  Unix.time () |> Unix.localtime |> fun t -> t.Unix.tm_year + 1900

let ask ?default prompt = function
  | Some s -> Ok s
  | None -> (
      let pp_default =
        Fmt.(option (string |> using (fun s -> " (" ^ s ^ ")")))
      in

      (* (match default with
       * | Some s -> Printf.printf "%s" s
       * | None -> ()); *)
      Fmt.pr "%a %s%a: %!"
        Fmt.(styled `Faint string)
        "question" prompt pp_default default;
      try
        Sys.catch_break true;
        let s = read_line () in
        Sys.catch_break false;
        match (s, default) with "", Some default -> Ok default | _ -> Ok s
      with Sys.Break -> Error (`Msg "Cancelled") )

let assert_ok = function
  | Ok x -> x
  | Error (`Msg msg) ->
      Logs.app (fun m -> m "\n%a %s." Fmt.(styled `Red string) "error" msg);
      exit 1

let ( >>= ) x f = match x with Ok x -> f x | e -> e
let run ~project_kind ?name ?project_synopsis ?maintainer_fullname
    ?maintainer_email ?github_organisation ~license ~dependencies ~version_dune
    ~version_ocaml ~version_opam ~version_ocamlformat ~ocamlformat_options
    ~dry_run ~git_repo ?(current_year = get_current_year ()) () =
  Logs.app (fun m -> m "%a" Fmt.(styled `Bold string) "oskel v%%VERSION%%");
  Random.self_init ();
  let name =
    ask ~default:(adjective_animal ()) "name" name
    >>= Validate.project
    |> assert_ok
  in
  let maintainer_fullname = ask "author" maintainer_fullname |> assert_ok in
  let maintainer_email = ask "email" maintainer_email |> assert_ok in
  let github_organisation =
    ask "GitHub name" github_organisation |> assert_ok
  in
  let project_synopsis = ask "synopsis" project_synopsis |> assert_ok in
  main ~project_kind ~dry_run
    {
      name;
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
