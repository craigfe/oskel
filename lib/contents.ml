open Config
open Utils

type file_printer = Config.t -> Format.formatter -> unit

let sexp_file_printer sexps ppf = Sexp_contents.pps ppf sexps

let dep_alcotest = { dep_name = "alcotest"; dep_filter = Some "with-test" }

let project_dependencies config =
  config.dependencies |> List.append [ dep_alcotest ] |> List.sort_uniq compare

module Dune_project = struct
  let package c =
    let open Sexp_contents in
    let author_contact =
      quoted (Fmt.str "%s <%s>" c.maintainer_fullname c.maintainer_email)
    in
    let depend dep =
      let name = atom dep.dep_name in
      match dep.dep_filter with
      | Some filter -> list [ name; atom (Fmt.str ":%s" filter) ]
      | None -> name
    in
    sexp_file_printer
      [
        atoms [ "lang"; "dune"; c.versions.dune ];
        atoms [ "name"; c.name ];
        atoms [ "implicit_transitive_deps"; "false" ];
        atoms [ "generate_opam_files"; "true" ];
        field "source"
          [ field "github" [ atom (Fmt.str "%s/%s" c.github_organisation c.name) ] ];
        field "maintainers" [ author_contact ];
        field "authors" [ author_contact ];
        field "package"
          [
            field "name" [ atom c.name ];
            field "synopsis" [ quoted c.project_synopsis ];
            field "description" [ quoted c.project_synopsis ];
            field "documentation"
              [ quoted (Fmt.str "https://%s.github.io/%s/" c.github_organisation c.name) ];
            field "depends" (List.map depend c.dependencies);
          ];
      ]

  let minimal config ppf = Fmt.pf ppf "(lang dune %s)" config.versions.dune
end

module Dune = struct
  open Sexp_contents

  let field_libraries = function
    | [] -> []
    | _ :: _ as deps -> [ field "libraries" (List.map atom deps) ]

  let library { name; _ } =
    let file = Utils_naming.file_of_project name in
    sexp_file_printer
      [
        field "library"
          ( [ field "name" [ atom file ]; field "public_name" [ atom name ] ]
          @ field_libraries [ "logs" ] );
      ]

  let executable ~name ?(libraries = []) =
    let file = Utils_naming.file_of_project name in
    sexp_file_printer
      [
        field "executable"
          ([ field "name" [ atom file ] ] @ field_libraries libraries);
      ]

  let install ~exe_name ~bin_name =
    sexp_file_printer
      [
        field "install"
          [
            field "section" [ atom "bin" ];
            field "files"
              [ list [ atom (Fmt.str "%s.exe" exe_name); atom "as"; atom bin_name ] ];
          ];
      ]

  let test config =
    let dependencies =
      [ config.name; "alcotest"; "logs"; "logs.fmt" ]
      |> List.sort String.compare
    in
    sexp_file_printer
      [
        field "test"
          ([ field "name" [ atom "main" ] ] @ field_libraries dependencies);
      ]

  let ppx_deriver { name = n; _ } =
    sexp_file_printer
      [
        field "library"
          ( [
              field "public_name" [ atom n ]; field "kind" [ atom "ppx_deriver" ];
            ]
          @ field_libraries [ n ^ "_lib"; "ppxlib" ] );
      ]

  let ppx_deriver_lib _ _ppf = ()

  let generate_help { name = n; _ } =
    sexp_file_printer
      [
        field "rule"
          [
            field "targets" [ atom (Fmt.str "%s-help.txt.gen" n) ];
            field "action"
              [
                field "with-stdout-to"
                  [
                    atom "%{targets}";
                    field "run" [ atom n; atom "--help=plain" ];
                  ];
              ];
          ];
        field "rule"
          [
            field "alias" [ atom "runtest" ];
            field "action"
              [
                field "diff"
                  [ atom (Fmt.str "%s-help.txt" n); atom (Fmt.str "%s-help.txt.gen" n) ];
              ];
          ];
      ]
end

let hello_world_bin _config ppf =
  Fmt.pf ppf "let () = print_endline \"Hello, World!\""

let hello_world_lib_ml _config ppf =
  Fmt.pf ppf
    {|let main () =
  let () = Logs.debug (fun m -> m "Program has started") in
  "Hello, World!"|}

let hello_world_lib_mli _config ppf = Fmt.pf ppf "val main : unit -> string"

let gitignore _config ppf =
  Fmt.pf ppf {|_build/
_opam/
*~
\.\#*
\#*#
*.install
.merlin|}

let readme config ppf =
  Fmt.pf ppf
    {|# %s

%s

## Installation

```
opam pin add --yes https://github.com/%s/%s.git
opam install %s
```

If you want to contribute to the project, please read
[CONTRIBUTING.md](CONTRIBUTING.md).|}
    config.name config.project_synopsis config.github_organisation config.name
    config.name

let contributing ?promote config ppf =
  Fmt.pf ppf
    {|## Setting up your working environment

%s requires OCaml %s or higher so you will need a corresponding opam
switch. You can install a switch with the latest OCaml version by running:

```
opam switch create 4.09.0 ocaml-base-compiler.4.09.0
```

To clone the project's sources and install both its regular and test
dependencies run:

```
git clone https://github.com:%s/%s.git
cd %s
opam install -t --deps-only .
```

From there you can build all of the project's public libraries and executables
with:

```
dune build @install
```

and run the test suite with:

```
dune runtest
```|}
    config.name config.versions.ocaml config.github_organisation config.name
    config.name;
  match promote with
  | Some () ->
      Fmt.pf ppf
        {|

If the test suite fails, it may propose a diff to fix the issue. You may accept
the proposed diff with `dune promote`.|}
  | None -> ()

let readme_ppx = readme

let changes { initial_version; _ } ppf = Fmt.pf ppf "# %s" initial_version

let ocamlformat config ppf =
  Fmt.pf ppf "@[<v 0>version = %s%a@]" config.versions.ocamlformat
    Fmt.(list (cut ++ pair ~sep:(const string " = ") string string))
    config.ocamlformat_options

let opam config ppf =
  let pp_homepage ppf config =
    Fmt.pf ppf "https://github.com/%s/%s" config.github_organisation config.name
  in
  let pp_bugreports ppf config = Fmt.pf ppf "%a/issues" pp_homepage config in
  let pp_devrepo ppf config =
    Fmt.pf ppf "git+https://github.com/%s/%s.git" config.github_organisation
      config.name
  in
  let pp_depend ppf dep =
    Fmt.pf ppf "%S%a" dep.dep_name Fmt.(option (fmt " {%s}")) dep.dep_filter
  in
  Fmt.pf ppf
    {|opam-version: "%s"
maintainer:   "%s"
authors:      ["%s"]
license:      "%a"
homepage:     "%a"
bug-reports:  "%a"
dev-repo:     "%a"

build: [
 ["dune" "subst"] {pinned}
 ["dune" "build" "-p" name "-j" jobs]
 ["dune" "runtest" "-p" name] {with-test}
]

depends: [
  "ocaml"   {>= "%s"}
  "dune"    {build & >= "%s"}
  @[<v 2>%a@]
]
synopsis: "%s"|}
    config.versions.opam config.maintainer_fullname config.maintainer_fullname
    Config.pp_license config.license pp_homepage config pp_bugreports config
    pp_devrepo config config.versions.ocaml config.versions.dune
    Fmt.(list ~sep:cut pp_depend)
    (project_dependencies config)
    config.project_synopsis

let test_main_ml config ppf =
  Fmt.pf ppf
    {|let test expected () =
  Alcotest.(check string) "test 0" expected (%s.main ())

let suite =
  [
    ("Dummy passing test", `Quick, test "Hello, World!");
    ("Dummy failing test", `Quick, test "Bye, World!");
  ]

let () =
  Logs.set_level (Some Logs.Debug);
  Logs.set_reporter (Logs_fmt.reporter ());
  Alcotest.run "%s" [ ("suite", suite) ]|}
    (Utils_naming.findlib_of_project config.name)
    config.name

let empty_mli _config ppf = Fmt.pf ppf "(* intentionally empty *)"

let src_ppx_deriver_ml config ppf =
  Fmt.pf ppf
    {|open Ppxlib
open Ppx_%s_lib

let ppx_name = "%s"

let expand_str ~loc ~path:_ input_ast name =
  let (module S) = Ast_builder.make loc in
  let (module L) = (module Deriver.Located (S) : Deriver.S) in
  L.derive_str ?name input_ast

let expand_sig ~loc ~path:_ input_ast name =
  let (module S) = Ast_builder.make loc in
  let (module L) = (module Deriver.Located (S) : Deriver.S) in
  L.derive_sig ?name input_ast

let str_type_decl_generator =
  let args = Deriving.Args.(empty +> arg "name" (estring __)) in
  let attributes = Attributes.all in
  Deriving.Generator.make ~attributes args expand_str

let sig_typ_decl_generator =
  let args = Deriving.Args.(empty +> arg "name" (estring __)) in
  Deriving.Generator.make args expand_sig

let %s =
  Deriving.add ~str_type_decl:str_type_decl_generator
    ~sig_type_decl:sig_typ_decl_generator ppx_name|}
    config.name config.name config.name

let src_ppx_deriver_mli config ppf =
  Fmt.pf ppf {|val %s : Ppxlib.Deriving.t
|} config.name

let dune_gen_dune_rules _ _ppf = ()

let gen_dune_rules_ml _ _ppf = ()

let bin_cmdliner config ppf =
  Fmt.pf ppf
    {|let main () = %s.main () |> print_endline

open Cmdliner

let setup_log =
  let init style_renderer level =
    Fmt_tty.setup_std_outputs ?style_renderer ();
    Logs.set_level level;
    Logs.set_reporter (Logs_fmt.reporter ())
  in
  Term.(const init $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let term =
  let doc = "%s" in
  let exits = Term.default_exits in
  let man = [] in
  Term.(const main $ setup_log, info "%s" ~doc ~exits ~man)

let () = Term.exit (Term.eval term)|}
    (Utils_naming.findlib_of_project config.name)
    config.project_synopsis config.name

let bin_help_txt config ppf =
  Fmt.pf ppf
    {|NAME
       %s - %s

SYNOPSIS
       %s [OPTION]... 

OPTIONS
       --color=WHEN (absent=auto)
           Colorize the output. WHEN must be one of `auto', `always' or
           `never'.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -q, --quiet
           Be quiet. Takes over -v and --verbosity.

       -v, --verbose
           Increase verbosity. Repeatable, but more than twice does not bring
           more.

       --verbosity=LEVEL (absent=warning)
           Be more or less verbose. LEVEL must be one of `quiet', `error',
           `warning', `info' or `debug'. Takes over -v.

EXIT STATUS
       %s exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).
|}
    config.name config.project_synopsis config.name config.name
