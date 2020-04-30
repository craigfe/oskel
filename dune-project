(lang dune 2.0)
(name oskel)
(implicit_transitive_deps false)

(generate_opam_files true)
(source (github CraigFe/oskel))
(maintainers "Craig Ferguson <me@craigfe.io>")
(authors "Craig Ferguson <me@craigfe.io>")

(package
 (name oskel)
 (synopsis "Skeleton generator for OCaml projects")
 (documentation https://CraigFe.github.io/oskel)
 (description "\
Skeleton generator for OCaml projects

oskel is a tool for generating stubs of OCaml projects pre-equipped with the
standard boilerplate: OCamlformat config file, Alcotest scaffolding,
auto-generation of [*.opam] files via [dune-project] etc. It supports generating
binaries with Cmdliner, Fmt and Logs support. The resulting projects are
compliant with [dune-release lint].
")
 (depends cmdliner (fmt (>= 0.8.7)) logs stdlib-shims ocaml-syntax-shims lwt))


