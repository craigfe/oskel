MD_FILES = *.md examples/**/*.md

.PHONY: examples
examples:
	dune clean
	dune build @examples
	find examples/ -mindepth 1 -maxdepth 1 -type d -exec rm -rf '{}' \;
	find _build/default/examples -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec cp -rf '{}' examples/ \;

.PHONY: lint
lint:
	prettier --check $(MD_FILES)
	dune build @fmt

.PHONY: format
format:
	prettier --check $(MD_FILES)
	dune build --auto-promote @fmt
