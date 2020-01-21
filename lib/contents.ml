open Config

type file_printer = Config.t -> Format.formatter -> unit

module Dune_project = struct
  let package c ppf =
    let dependencies =
      c.dependencies
      |> List.append [ "alcotest" ]
      |> List.sort_uniq String.compare
    in
    Fmt.pf ppf
      {|(lang dune %s)
(name %s)
(implicit_transitive_deps false)

(generate_opam_files true)
(source (github %s/%s))
(maintainers "%s <%s>")
(authors "%s <%s>")

(package
 (name %s)
 (synopsis "%s")
 (description "\
%s
")
 (documentation https://%s.github.io/%s/)
 (depends %a))|}
      c.version_dune c.project c.github_organisation c.project
      c.maintainer_fullname c.maintainer_email c.maintainer_fullname
      c.maintainer_email c.project c.project_synopsis c.project_synopsis
      c.github_organisation c.project
      Fmt.(list ~sep:(const string " ") string)
      dependencies

  let minimal config ppf = Fmt.pf ppf "(lang dune %s)" config.version_dune
end

module Dune = struct
  let library config ppf =
    Fmt.pf ppf {|(library
 (name %s)
 (libraries logs))|} config.project

  let pp_libraries ppf deps =
    match deps with
    | [] -> ()
    | _ :: _ ->
        let open Fmt in
        pf ppf "@,(libraries %a)" (list ~sep:(const string " ") string) deps

  let executable ~name ?(libraries = []) ppf =
    Fmt.pf ppf "@[<v 1>(executable@,(name %s)%a)@]" name pp_libraries libraries

  let install ~exe_name ~bin_name ppf =
    Fmt.pf ppf
      "@[<v 1>(install@,(section bin)@,@[<v 1>(files@,(%s.exe as %s))@])@]"
      exe_name bin_name

  let test config ppf =
    let dependencies =
      [ config.project; "alcotest"; "logs"; "logs.fmt" ]
      |> List.sort String.compare
    in
    Fmt.pf ppf "@[<v 1>(test@,(name main)%a)@]" pp_libraries dependencies

  let ppx_deriver config ppf =
    Fmt.pf ppf
      {|(library
 (public_name %s)
 (kind ppx_deriver)
 (libraries %s_lib ppxlib))|}
      config.project config.project

  let ppx_deriver_lib _ _ppf = ()

  let generate_help config ppf =
    Fmt.pf ppf
      {|(rule
 (targets %s-help.txt.gen)
 (action
  (with-stdout-to
   %%{targets}
   (run %s --help=plain))))

(rule
 (alias runtest)
 (action
  (diff %s-help.txt %s-help.txt.gen)))|}
      config.project config.project config.project config.project
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
    config.project config.project_synopsis config.github_organisation
    config.project config.project

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
    config.project config.version_ocaml config.github_organisation
    config.project config.project;
  match promote with
  | Some () ->
      Fmt.pf ppf
        {|

If the test suite fails, it may propose a diff to fix the issue. You may accept
the proposed diff with `dune promote`.|}
  | None -> ()

let readme_ppx = readme

let changes _config ppf = Fmt.pf ppf "# 0.1.0"

let ocamlformat config ppf =
  Fmt.pf ppf "@[<v 0>version = %s%a@]" config.version_ocamlformat
    Fmt.(list (cut ++ pair ~sep:(const string " = ") string string))
    config.ocamlformat_options

let opam config ppf =
  let pp_homepage ppf config =
    Fmt.pf ppf "https://github.com/%s/%s" config.github_organisation
      config.project
  in
  let pp_bugreports ppf config = Fmt.pf ppf "%a/issues" pp_homepage config in
  let pp_devrepo ppf config =
    Fmt.pf ppf "git+https://github.com/%s/%s.git" config.github_organisation
      config.project
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
  "fmt"
  "logs"
  "alcotest" {with-test}
]
synopsis: "%s"|}
    config.version_opam config.maintainer_fullname config.maintainer_fullname
    Config.pp_license config.license pp_homepage config pp_bugreports config
    pp_devrepo config config.version_ocaml config.version_dune
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
    (String.capitalize_ascii config.project)
    config.project

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
    config.project config.project config.project

let src_ppx_deriver_mli config ppf =
  Fmt.pf ppf {|val %s : Ppxlib.Deriving.t
|} config.project

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
    (String.capitalize_ascii config.project)
    config.project_synopsis config.project

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
    config.project config.project_synopsis config.project config.project
