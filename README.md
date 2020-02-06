# :skull: oskel: skeleton generator for OCaml projects

[![asciicast](./.assets/asciicast.gif)](https://asciinema.org/a/298707)

The standard project type is initialised with:

- [`.opam` file autogeneration][dune-opam-files] via `dune-project`;
- [OCamlformat][ocamlformat] config file;
- [Alcotest][alcotest] testing boilerplate, with pre-configured [Logs][logs]
  initialisation.
- Git repository with an initial commit;
- OCaml `.gitignore`;
- `README.md` with installation instructions for `opam`.

## Choice of project layouts

There are multiple project structures, which can be selected via the `--kind`
flag:

- [`library`][example-library] (**default**): library-only package;
- [`executable`][example-executable]: a single binary with minimal
  configuration;
- [`binary`][example-binary]: package providing a [Cmdliner][cmdliner] binary in
  `bin/`, making use of a tested library in `lib/`.

<!-- Work in progress
- [`ppx_deriver`][example-ppx_deriver]: boilerplate for a
  [ppx_deriving][ppx_deriving] plugin, using a [modern PPX
  workflow][nathanreb-ppx-blog];
-->

Examples of each layout can be seen in the [`examples/`][examples] directory.
You can also use e.g. `oskel --dry-run --kind executable` to see a preview of
the project structure.

## Installation

```
opam install oskel
```

If you want to contribute to the project, please read
[CONTRIBUTING.md](CONTRIBUTING.md).

## Configuration

`oskel` is very configurable (see [`oskel --help`](./oskel-help.txt) for
details). Most options can be set via environment variables. In particular, you
can set your personal metadata in your shell `.profile`:

```
export OSKEL_FULL_NAME="Joe Bloggs"
export OSKEL_EMAIL="joe@example.com"
export OSKEL_GITHUB_ORG="JoeBlo"
```

<!-- prettier-ignore-start -->
[examples]: https://github.com/CraigFe/oskel/tree/master/examples
[example-library]: https://github.com/CraigFe/oskel/tree/master/examples/library
[example-binary]: https://github.com/CraigFe/oskel/tree/master/examples/binary
[example-ppx_deriver]: https://github.com/CraigFe/oskel/tree/master/examples/ppx_deriver
[example-executable]: https://github.com/CraigFe/oskel/tree/master/examples/executable
[dune-opam-files]: https://dune.readthedocs.io/en/stable/opam.html#generating-opam-files
[logs]: https://erratique.ch/software/logs
[cmdliner]: https://erratique.ch/software/cmdliner
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat/
[alcotest]: https://github.com/mirage/alcotest/
[ppx_deriving]: https://github.com/ocaml-ppx/ppx_deriving
[nathanreb-ppx-blog]: https://tarides.com/blog/2019-05-09-an-introduction-to-ocaml-ppx-ecosystem
<!-- prettier-ignore-end -->
