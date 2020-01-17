## Setting up your working environment

library requires OCaml 4.09.0 or higher so you will need a corresponding opam switch
which you can install by running:
```
opam switch create 4.09.0 ocaml-base-compiler.4.09.0
```

To clone the project's sources and install both its regular and test
dependencies run:
```
git clone https://github.com:JoeBloggs/library.git
cd library
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
