type file

val pp_file : file Fmt.t

type project

val pp_project : Config.t -> project Fmt.t

val library : project

val binary : project

val executable : project

val project_of_kind : [ `Binary | `Executable | `Library ] -> project

val instantiate : Config.t -> project -> (unit, [ `Msg of string ]) result
