module License = License
module Utils = Utils
open Utils
open Result.Infix

let default_opam_version = "2.0"

let progress_bar msg : (unit -> unit Lwt.t) * bool ref * bool ref =
  let ( >>= ) = Lwt.bind in
  let finished = ref false in
  let active = ref false in
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
      Printf.printf "\r[ %s ] %s%!" (List.hd frames) msg;
      Lwt_unix.sleep 0.1
      (* Logs_lwt.app (fun m -> m "%s %s\r" (List.hd frames) msg) *)
      >>= fun () -> loop (List.tl frames)
  in
  ((fun () -> loop frames), finished, active)

let package_to_string = function
  | `Dune -> "dune"
  | `OCaml -> "ocaml"
  | `OCamlformat -> "ocamlformat"

let get_last_in_line (tag, available_versions) =
  available_versions
  |> String.split_on_char ' '
  |> List.rev
  |> function
  | latest :: _ -> Ok (tag, latest)
  | [] ->
      Result.errorf "No available versions for package `%s`"
        (package_to_string tag)

type versions = (Config.versions, [ `Msg of string ]) result Lwt.t

let v_versions (`Dune dune) (`OCaml ocaml) (`Opam opam)
    (`OCamlformat ocamlformat) : versions =
  let ( let+ ) x f = Lwt.map (Result.map f) x in
  let packages =
    (* These must be in alphabetical order, as [opam] always reports results in
       this order. See https://github.com/ocaml/opam/issues/4163. *)
    [ (`Dune, dune); (`OCaml, ocaml); (`OCamlformat, ocamlformat) ]
  in

  (* Opam queries are slow, so we only query for the latest versions of packages
     that aren't already specified. *)
  let packages_to_query =
    packages
    |> List.filter_map (fun (tag, version) ->
           match version with Some _ -> None | None -> Some tag)
  in

  let+ packages =
    match packages_to_query with
    (* No query necessary *)
    | [] -> Lwt.return (Ok (packages |> List.map (T2.map2 Option.get)))
    | _ :: _ ->
        packages_to_query
        |> List.map package_to_string
        |> Utils_unix.execf "opam show --field=available-versions -- %a"
             Fmt.(list ~sep:sp string)
        |> Lwt.map (fun r ->
               r
               >>| List.combine packages_to_query
               >>= (List.map get_last_in_line >> List.sequence_result))
  in

  let dune = List.assoc `Dune packages
  and ocaml = List.assoc `OCaml packages
  and ocamlformat = List.assoc `OCamlformat packages
  and opam = Option.value ~default:default_opam_version opam in
  Config.{ opam; dune; ocaml; ocamlformat }

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

let ask ~non_interactive ?default prompt = function
  | Some s -> Lwt.return (Ok s)
  | None -> (
      let ( let+ ) x f = Lwt.map f x in
      if non_interactive then
        Lwt.return
          (Result.errorf "Must set '%s' or enable interactive mode" prompt)
      else
        let pp_default =
          Fmt.(option (string |> using (fun s -> " (" ^ s ^ ")")))
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
        | _ -> Ok line )

let assert_ok = function
  | Ok x -> x
  | Error (`Msg msg) ->
      Logs.app (fun m -> m "\n%a %s." Fmt.(styled `Red string) "error" msg);
      exit 1

let adjective_animal () =
  let random_elt l = List.length l |> Random.int |> List.nth l in
  Fmt.strf "%s-%s" (random_elt Faker.adjectives) (random_elt Faker.animals)

let ( let* ) = Lwt.bind

and ( let+ ) x f = Lwt.map f x

and ( and+ ) = Lwt.both

let populate_config ~non_interactive ~name ~maintainer_fullname
    ~maintainer_email ~github_organisation ~project_synopsis ~initial_version =
  let ( >|= ) x f = Lwt.map f x in
  let* name =
    ask ~non_interactive ~default:(adjective_animal ()) "name" name
    >|= fun x -> Result.bind x Validate.project |> assert_ok
  in
  let* maintainer_fullname =
    ask ~non_interactive "author" maintainer_fullname >|= assert_ok
  in
  let* maintainer_email =
    ask ~non_interactive "email" maintainer_email >|= assert_ok
  in
  let* github_organisation =
    ask ~non_interactive "GitHub name" github_organisation >|= assert_ok
  in
  let* project_synopsis =
    ask ~non_interactive "synopsis" project_synopsis >|= assert_ok
  in
  let* initial_version =
    ask ~non_interactive ~default:"0.1.0" "version" initial_version
    >|= assert_ok
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
    ~maintainer_email ?github_organisation ?initial_version ~license
    ~dependencies ~(versions : versions) ~ocamlformat_options ~dry_run
    ~non_interactive ~git_repo ?(current_year = get_current_year ()) () =
  let ( >>= ) = Lwt.bind and ( >>| ) x f = Lwt.map f x in
  Random.self_init ();
  let promise =
    let* () =
      Logs_lwt.app (fun m ->
          m "%a" Fmt.(styled `Bold string) "oskel v%%VERSION%%")
    in
    let* maintainer_fullname = maintainer_fullname in
    let* maintainer_email = maintainer_email in
    let config =
      populate_config ~non_interactive ~name ~maintainer_fullname
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
    let versions = versions |> assert_ok in
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
