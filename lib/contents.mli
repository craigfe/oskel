type file_printer = Config.t -> Format.formatter -> unit

module Dune_project : sig
  val package : file_printer

  val minimal : file_printer
end

module Dune : sig
  val library : file_printer

  val executable :
    name:string -> ?libraries:string list -> Format.formatter -> unit

  val install : exe_name:string -> bin_name:string -> Format.formatter -> unit

  val test : file_printer

  val ppx_deriver : file_printer

  val ppx_deriver_lib : file_printer

  val generate_help : file_printer
end

val gitignore : file_printer

val readme : file_printer

val contributing : ?promote:unit -> file_printer

val readme_ppx : file_printer

val changes : file_printer

val ocamlformat : file_printer

val opam : file_printer

val hello_world_bin : file_printer

val hello_world_lib_ml : file_printer

val hello_world_lib_mli : file_printer

val test_main_ml : file_printer

val empty_mli : file_printer

val src_ppx_deriver_ml : file_printer

val src_ppx_deriver_mli : file_printer

val dune_gen_dune_rules : file_printer

val gen_dune_rules_ml : file_printer

val bin_cmdliner : file_printer

val bin_help_txt : file_printer
