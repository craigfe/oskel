type file

val pp_file : file Fmt.t

type project

val pp_project : Config.t -> project Fmt.t

val library : project

val binary : project

val executable : project

val instantiate : Config.t -> project -> (unit, string) result
