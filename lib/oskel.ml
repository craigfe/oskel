module License = License
module Utils = Utils
module Opam = Opam
open Utils

let stdout_is_tty = Unix.(isatty stdout)

let progress_bar msg : (unit -> unit Lwt.t) * bool ref * bool ref =
  let ( >>= ) = Lwt.bind in
  let finished = ref false in
  let active = ref false in
  let shown_once = ref false in
  let rec frames =
    "⠋"
    :: "⠙"
    :: "⠹"
    :: "⠸"
    :: "⠼"
    :: "⠴"
    :: "⠦"
    :: "⠧"
    :: "⠇"
    :: "⠏"
    :: frames
  in
  let rec loop frames =
    if !finished then Lwt.return ()
    else
      (* Initial space *)
      let () =
        if not !active then Printf.printf "\n";
        active := true
      in
      if stdout_is_tty || not !shown_once then (
        if !shown_once then Printf.printf "\r";
        Printf.printf "[ %s ] %s%!" (List.hd frames) msg;
        shown_once := true );
      Lwt_unix.sleep 0.1
      (* Logs_lwt.app (fun m -> m "%s %s\r" (List.hd frames) msg) *)
      >>= fun () -> loop (List.tl frames)
  in
  ((fun () -> loop frames), finished, active)

let main ~dry_run ~project_kind config =
  let project = Layouts.project_of_kind project_kind in
  Logs.app (fun m -> m "@[<v>@,%a@]" (Layouts.pp_project config) project);
  if not dry_run then
    match Layouts.instantiate config project with
    | Ok () ->
        Logs.app (fun m ->
            m "%a Created new project in `%a'"
              Fmt.(styled `Green string)
              "success"
              Fmt.(styled `Blue string)
              (Sys.getcwd ()))
    | Error (`Msg msg) ->
        Fmt.epr "%s" msg;
        exit 1

let get_current_year () =
  Unix.time () |> Unix.localtime |> fun t -> t.Unix.tm_year + 1900

let ask ~non_interactive ~assume_yes ?default prompt = function
  | Some s -> Lwt.return (Ok s)
  | None -> (
      let ( let+ ) x f = Lwt.map f x in
      match (assume_yes, non_interactive, default) with
      | true, _, Some default -> Lwt.return (Ok default)
      | true, _, None ->
          Lwt.return (Result.errorf "No default available for `%s'" prompt)
      | false, true, Some _ ->
          Lwt.return
            (Result.errorf
               "Must set `%s', assume defaults with `--assume-yes', or enable \
                interactive mode"
               prompt)
      | false, true, None ->
          Lwt.return
            (Result.errorf "Must set `%s' or enable interactive mode" prompt)
      | false, false, _ -> (
          let pp_default =
            Fmt.(
              option
                (string |> using (function "" -> "" | s -> " (" ^ s ^ ")")))
          in
          Fmt.pr "%a %s%a: %!"
            Fmt.(styled `Faint string)
            "question" prompt pp_default default;
          let+ line =
            Sys.catch_break true;
            let+ line = Lwt_io.read_line Lwt_io.stdin in
            Sys.catch_break false;
            line
          in
          match (line, default) with
          | "", Some default -> Ok default
          | _ -> Ok line ) )

let show_error (type a) msg : a =
  Logs.app (fun m -> m "\n%a %s." Fmt.(styled `Red string) "error" msg);
  exit 1

let show_errorf fmt = Format.kasprintf show_error fmt

let assert_ok = function Ok x -> x | Error (`Msg msg) -> show_error msg

let adjective_animal () =
  let random_elt l = List.length l |> Random.int |> List.nth l in
  Fmt.strf "%s-%s" (random_elt Faker.adjectives) (random_elt Faker.animals)

let ( let* ) = Lwt.bind

and ( let+ ) x f = Lwt.map f x

and ( and+ ) = Lwt.both

let populate_config ~non_interactive ~assume_yes ~name ~maintainer_fullname
    ~maintainer_email ~github_organisation ~project_synopsis ~initial_version =
  let ( >|= ) x f = Lwt.map f x in
  let ask = ask ~non_interactive ~assume_yes in
  let* name =
    ask ~default:(adjective_animal ()) "name" name
    >|= fun x -> Result.bind x Validate.project |> assert_ok
  in
  let* maintainer_fullname = ask "author" maintainer_fullname >|= assert_ok in
  let* maintainer_email = ask "email" maintainer_email >|= assert_ok in
  let* github_organisation =
    ask "GitHub name" github_organisation >|= assert_ok
  in
  let* project_synopsis =
    ask ~default:"" "synopsis" project_synopsis >|= assert_ok
  in
  let* initial_version =
    ask ~default:"0.1.0" "version" initial_version >|= assert_ok
  in
  Lwt.return
    (object
       method name = name

       method maintainer_fullname = maintainer_fullname

       method maintainer_email = maintainer_email

       method github_organisation = github_organisation

       method project_synopsis = project_synopsis

       method initial_version = initial_version
    end)

let run ~project_kind ?name ?project_synopsis ~maintainer_fullname
    ~maintainer_email ?github_organisation ?initial_version ?working_dir
    ~assume_yes ~license ~dependencies ~(versions : Opam.versions)
    ~ocamlformat_options ~dry_run ~non_interactive ~git_repo
    ?(current_year = get_current_year ()) () =
  let ( >>= ) = Lwt.bind and ( >>| ) x f = Lwt.map f x in
  Random.self_init ();
  (match working_dir with None -> () | Some dir -> Sys.chdir dir);
  let promise =
    let* () =
      Logs_lwt.app (fun m ->
          m "%a" Fmt.(styled `Bold string) "oskel v%%VERSION%%")
    in
    let* maintainer_fullname = maintainer_fullname in
    let* maintainer_email = maintainer_email in
    let config =
      populate_config ~non_interactive ~assume_yes ~name ~maintainer_fullname
        ~maintainer_email ~github_organisation ~project_synopsis
        ~initial_version
    in
    let progress, finished, progress_bar_active =
      progress_bar "Getting latest version numbers via `opam info`"
    in
    let ( >* ) a b = a >>= fun a -> b () >>| fun () -> a in
    let+ versions =
      versions
      >* Lwt.(
           fun () ->
             finished := true;
             if !progress_bar_active then Printf.printf "\r\n%!";
             return ())
    and+ c = config >* progress in
    let dependencies =
      List.map
        (fun dep_name -> { Config.dep_name; dep_filter = None })
        dependencies
    in
    let versions =
      versions
      |> function
      | Ok x -> x
      | Error (`Msg msg) -> show_error msg
      | Error (`Command_not_found cmd) ->
          show_errorf
            "Command `%s` not found (error code 127). Either install `%s` or \
             specify versions of Dune, OCaml and OCamlformat explicitly"
            cmd cmd
    in

    main ~project_kind ~dry_run
      {
        name = c#name;
        project_synopsis = c#project_synopsis;
        maintainer_fullname = c#maintainer_fullname;
        maintainer_email = c#maintainer_email;
        github_organisation = c#github_organisation;
        initial_version = c#initial_version;
        license;
        dependencies;
        versions;
        ocamlformat_options;
        current_year;
        git_repo;
      };
    Ok ()
  in
  (try Lwt_main.run promise with Sys.Break -> Error (`Msg "Cancelled"))
  |> assert_ok
