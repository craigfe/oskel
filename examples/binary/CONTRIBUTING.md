## Setting up your working environment

binary requires OCaml [m4.14.0[0m or higher so you will need a corresponding opam
switch. You can install a switch with the latest OCaml version by running:

```
opam switch create 4.09.0 ocaml-base-compiler.4.09.0
```

To clone the project's sources and install both its regular and test
dependencies run:

```
git clone https://github.com:JoeBloggs/binary.git
cd binary
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
```

If the test suite fails, it may propose a diff to fix the issue. You may accept
the proposed diff with `dune promote`.
