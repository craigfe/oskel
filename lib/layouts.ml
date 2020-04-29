open Utils

type file =
  | Folder of string * file list
  | File of string * (Format.formatter -> unit)

type project = { layout : Config.t -> file; post_init : string list }

let compare_file a b =
  match (a, b) with
  | Folder _, File _ -> -1
  | File _, Folder _ -> 1
  | Folder (a, _), Folder (b, _) -> String.compare a b
  | File (a, _), File (b, _) -> String.compare a b

let rec pp_file ~pre ~last_dir ppf =
  let open Fmt in
  let pp_files ~pre ~last_dir ppf files =
    (* Only print newline at the end if our ancestors have not already done so
       (i.e. we are not the descendant of a last directory *)
    let pp_last_dir ppf last_dir = if not last_dir then pf ppf "@,%s" pre in
    let pp_children_last ppf =
      pf ppf "%s`-- %a" pre (pp_file ~last_dir:true ~pre:(pre ^ "    "))
    and pp_children_not_last ppf =
      pf ppf "%s|-- %a" pre (pp_file ~last_dir:false ~pre:(pre ^ "|   "))
    in
    match files with
    | [] -> ()
    | [ last ] -> pf ppf "@,%a%a" pp_children_last last pp_last_dir last_dir
    | _ :: _ :: _ ->
        let last, not_last =
          files
          |> List.sort compare_file
          |> List.rev
          |> fun x -> (List.hd x, List.rev (List.tl x))
        in
        pf ppf "@,%a@,%a%a"
          (list ~sep:cut pp_children_not_last)
          not_last pp_children_last last pp_last_dir last_dir
  in
  let pp_folder_name = styled `Bold (styled `Blue string) in
  function
  | File (s, _) -> pf ppf "%s" s
  | Folder (s, children) ->
      pf ppf "%a%a" pp_folder_name s (pp_files ~pre ~last_dir) children

let pp_file = pp_file ~pre:"" ~last_dir:false

let pp_project config = Fmt.using (fun { layout; _ } -> layout config) pp_file

let license (config : Config.t) =
  License.v config.license ~year:config.current_year
    ~author:config.maintainer_fullname

let library (config : Config.t) =
  let open Contents in
  let src_file = Utils_naming.file_of_project config.name in
  Folder
    ( config.name,
      [
        Folder
          ( "src",
            [
              File ("dune", Dune.library config);
              File (src_file ^ ".ml", hello_world_lib_ml config);
              File (src_file ^ ".mli", hello_world_lib_mli config);
            ] );
        Folder
          ( "test",
            [
              File ("dune", Dune.test config);
              File ("main.ml", test_main_ml config);
              File ("main.mli", empty_mli config);
            ] );
        File (".gitignore", gitignore config);
        File (".ocamlformat", ocamlformat config);
        File ("dune-project", Dune_project.package config);
        File ("LICENSE", license config);
        File ("README.md", readme config);
        File ("CONTRIBUTING.md", contributing config);
        File ("CHANGES.md", changes config);
        (* Empty structure here only for pretty-printing to the user  *)
        File (config.name ^ ".opam", fun _ -> ());
      ]
      @ if config.git_repo then [ Folder (".git", []) ] else [] )

let library = { layout = library; post_init = [] }

let binary (config : Config.t) =
  let open Contents in
  let exe_name = "main" in
  let lib_file = Utils_naming.file_of_project config.name in
  let bin_dune ppf =
    let libraries =
      [
        config.name;
        "cmdliner";
        "fmt";
        "fmt.cli";
        "fmt.tty";
        "logs";
        "logs.cli";
        "logs.fmt";
      ]
      |> List.sort String.compare
    in
    Dune.executable ~name:exe_name ~libraries ppf;
    Fmt.pf ppf "\n";
    Dune.install ~exe_name ~bin_name:config.name ppf
  in
  Folder
    ( config.name,
      [
        Folder
          ( "bin",
            [
              File ("dune", bin_dune);
              File (exe_name ^ ".ml", bin_cmdliner config);
              File (exe_name ^ ".mli", empty_mli config);
            ] );
        Folder
          ( "lib",
            [
              File ("dune", Dune.library config);
              File (lib_file ^ ".ml", hello_world_lib_ml config);
              File (lib_file ^ ".mli", hello_world_lib_mli config);
            ] );
        Folder
          ( "test",
            [
              File ("dune", Dune.test config);
              File ("main.ml", test_main_ml config);
              File ("main.mli", empty_mli config);
            ] );
        Folder ("test", []);
        File (".gitignore", gitignore config);
        File (".ocamlformat", ocamlformat config);
        File ("dune", Dune.generate_help config);
        File ("dune-project", Dune_project.package config);
        File ("LICENSE", license config);
        File ("README.md", readme config);
        File ("CONTRIBUTING.md", contributing ~promote:() config);
        File ("CHANGES.md", changes config);
        File (config.name ^ "-help.txt", bin_help_txt config);
        (* Empty structure here only for pretty-printing to the user  *)
        File (config.name ^ ".opam", fun _ -> ());
      ]
      @ if config.git_repo then [ Folder (".git", []) ] else [] )

let binary = { layout = binary; post_init = [] }

let executable (config : Config.t) =
  let name = config.name in
  let toplevel_file = Utils.Utils_naming.file_of_project name in
  let libraries = config.dependencies in
  let open Contents in
  Folder
    ( config.name,
      [
        File ("dune-project", Dune_project.minimal config);
        File ("dune", Dune.executable ~name ~libraries);
        File (toplevel_file ^ ".ml", hello_world_bin config);
      ] )

let executable = { layout = executable; post_init = [] }

(* Work in progress *)
let _ppx_deriver (config : Config.t) =
  let open Contents in
  let toplevel_file = Utils_naming.file_of_project config.name in
  Folder
    ( config.name,
      [
        Folder
          ( "deriver",
            [
              File ("dune", Dune.ppx_deriver config);
              File (toplevel_file ^ ".ml", src_ppx_deriver_ml config);
              File (toplevel_file ^ ".mli", src_ppx_deriver_mli config);
            ] );
        Folder ("lib", [ File ("dune", Dune.ppx_deriver_lib config) ]);
        Folder
          ( "test",
            [
              Folder
                ( "deriver",
                  [
                    Folder ("errors", []);
                    Folder ("passing", []);
                    File ("dune", dune_gen_dune_rules config);
                    File ("gen_dune_rules.ml", gen_dune_rules_ml config);
                  ] );
            ] );
        File (".gitignore", gitignore config);
        File (".ocamlformat", ocamlformat config);
        File ("dune-project", Dune.library config);
        File ("LICENSE", license config);
        File ("README.md", readme_ppx config);
        File ("CONTRIBUTING.md", contributing config);
        File ("CHANGES.md", changes config);
        (* Empty structure here only for pretty-printing to the user  *)
        File (config.name ^ ".opam", fun _ -> ());
      ]
      @ if config.git_repo then [ Folder (".git", []) ] else [] )

let project_of_kind = function
  | `Library -> library
  | `Binary -> binary
  | `Executable -> executable

let post_initialise config after =
  let open Config in
  Sys.chdir config.name;
  Utils_unix.sequence_commands
    ( ( if config.git_repo then
        [
          (* initialise git repository *)
          "git init --quiet";
          "git add .";
          "git commit --quiet -m \"Initial commit\"";
          Fmt.strf "git remote add origin https://github.com/%s/%s.git"
            config.github_organisation config.name;
        ]
      else [] )
    @ after )

let instantiate config { layout; post_init } =
  let rec aux root = function
    | Folder (name, contents) ->
        let path = Filename.concat root name in
        Logs.debug (fun m -> m "Creating folder %s" path);
        Utils_unix.mkdir_p path;
        contents |> List.iter (aux path)
    | File (name, printer) ->
        let path = Filename.concat root name in
        Logs.debug (fun m -> m "Creating file %s" path);
        Utils_unix.print_to_file path printer
  in
  aux Filename.current_dir_name (layout config);
  post_initialise config post_init
