open Utils

let default_opam_version = "2.0"

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

type versions =
  (Config.versions, [ `Msg of string | `Command_not_found of string ]) result
  Lwt.t

let get_versions (`Dune dune) (`OCaml ocaml) (`Opam opam)
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
    let ( >>|* ) = List.Infix.( >>| ) in
    let open Result.Infix in
    match packages_to_query with
    (* No query necessary *)
    | [] -> Lwt.return (Ok (packages >>|* T2.map2 Option.get))
    | _ :: _ ->
        packages_to_query
        >>|* package_to_string
        |> Utils_unix.execf "opam show --field=available-versions -- %a"
             Fmt.(list ~sep:sp string)
        |> Lwt.map
             ( Result.map (List.combine packages_to_query)
             >=> List.(map get_last_in_line >> sequence_result) )
  in

  let dune = List.assoc `Dune packages
  and ocaml = List.assoc `OCaml packages
  and ocamlformat = List.assoc `OCamlformat packages
  and opam = Option.value ~default:default_opam_version opam in
  Config.{ opam; dune; ocaml; ocamlformat }
