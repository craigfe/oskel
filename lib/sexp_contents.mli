(** Pretty-print sexps. *)

type t

val atom : string -> t
(** Never quoted. *)

val quoted : string -> t
(** Always quoted. *)

val list : t list -> t

val atoms : string list -> t
(** A list containing atoms. *)

val field : string -> t list -> t
(** [(name arguments)] *)

val pp : t Fmt.t

val pps : t list Fmt.t
