type t = Apache2 | Bsd2 | Bsd3 | Isc | Mit

val all : (string * t) list

val v : t -> year:int -> author:string -> Format.formatter -> unit
