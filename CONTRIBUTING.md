## Setting up your working environment

Oskel requires OCaml 4.05.0 or higher so you will need a corresponding opam
switch. OCaml 4.09.0 is a good choice as it makes for a better developper
experience thanks to improved error messages, amongst other things. You can
install a 4.09.0 OCaml switch by running:
```
opam switch create 4.09.0 ocaml-base-compiler.4.09.0
```

To clone the project's sources and install both its regular and test
dependencies run:
```
git clone https://github.com:CraigFe/oskel.git
cd oskel
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

## Generating the examples

The repo contains examples of projects that were generated with `oskel`. When
modifying the various skeletons you should refresh the examples so that they
reflect the changes you introduced. You can do so by running:
```
make examples
```

If you add a new project layout, edit [`examples/dune`](examples/dune)
to generate a new example folder showcasing it:
```
    (progn
     (run oskel --synopsis "Single package in `src`" --kind=library library)
+    (run oskel --synopsis "<describe your layout>" --kind=<new_layout> <new_layout>)
     (run oskel --synopsis "Binary that depends on a tested library"
       --kind=binary binary)
     (run oskel --synopsis "Individual executable" --kind=executable
       executable)))))
```
