
.PHONY: examples
examples:
	dune clean
	dune build @examples
	find examples/ -mindepth 1 -maxdepth 1 -type d -exec rm -rf '{}' \;
	find _build/default/examples -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec cp -rf '{}' examples/ \;
