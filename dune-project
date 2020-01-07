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
 (depends cmdliner (fmt (>= 0.8.7))))


