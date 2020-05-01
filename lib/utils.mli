val ( >> ) : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c
(** Left-to-right function composition. *)

module T2 : sig
  val map1 : ('a -> 'b) -> 'a * 'c -> 'b * 'c

  val map2 : ('b -> 'c) -> 'a * 'b -> 'a * 'c
end

module T3 : sig
  val map : ('a -> 'b) -> 'a * 'a * 'a -> 'b * 'b * 'b
end

module List : sig
  include module type of List

  val filter_map : ('a -> 'b option) -> 'a list -> 'b list

  module Infix : sig
    val ( >>| ) : 'a list -> ('a -> 'b) -> 'b list
  end

  val sequence_result : ('a, 'e) result list -> ('a list, 'e) result
end

module Option : sig
  type 'a t = 'a option

  val get : 'a t -> 'a

  val value : 'a option -> default:'a -> 'a
end

module Result : sig
  type ('a, 'e) t = ('a, 'e) result

  val map : ('a -> 'b) -> ('a, 'e) t -> ('b, 'e) t

  val bind : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t

  val errorf :
    ('a, Format.formatter, unit, ('b, [> `Msg of string ]) result) format4 -> 'a

  module Infix : sig
    val ( >>= ) : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t

    val ( >>| ) : ('a, 'e) t -> ('a -> 'b) -> ('b, 'e) t

    val ( >=> ) : ('a -> ('b, 'e) t) -> ('b -> ('c, 'e) t) -> 'a -> ('c, 'e) t
  end

  module Syntax : sig
    val ( let* ) : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t

    val ( let+ ) : ('a, 'e) t -> ('a -> 'b) -> ('b, 'e) t
  end
end

module Utils_unix : sig
  val exec :
    string ->
    (string list, [ `Msg of string | `Command_not_found of string ]) result
    Lwt.t

  val execf :
    ( 'a,
      Format.formatter,
      unit,
      (string list, [ `Msg of string | `Command_not_found of string ]) result
      Lwt.t )
    format4 ->
    'a
  (** [execf] is like {!exec} but consumes a format string. *)

  val sequence_commands : string list -> (unit, [ `Msg of string ]) result

  val print_to_file : string -> (Format.formatter -> unit) -> unit

  val mkdir_p : string -> unit
end

module Utils_naming : sig
  val file_of_project : string -> string
  (** Given an opam package name, derive a conventional name for the top-level
      file name. Replaces all '-' characters with '_'. *)

  val findlib_of_project : string -> string
  (** Like {!file_of_project} but capitalised. *)
end
