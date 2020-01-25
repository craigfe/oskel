val exec : string -> (string, [ `Msg of string ]) result

val sequence_commands : string list -> (unit, [ `Msg of string ]) result

val print_to_file : string -> (Format.formatter -> unit) -> unit

val mkdir_p : string -> unit
