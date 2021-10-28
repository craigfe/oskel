type t = Atom of string | Quoted of string | List of t list

let atom s = Atom s

let quoted s = Quoted s

let list ts = List ts

let atoms ss = List (List.map (fun s -> Atom s) ss)

let field name arguments = List (Atom name :: arguments)

open Fmt

let only_atoms =
  List.for_all (function Atom _ | Quoted _ -> true | List _ -> false)

let rec pp ppf = function
  | Atom s -> string ppf s
  | Quoted s -> pf ppf "%S" s
  | List ts when only_atoms ts -> pf ppf "(@[<hv>%a)@]" (list ~sep:sp pp) ts
  | List ts -> pf ppf "(@[<v>%a)@]" (list ~sep:sp pp) ts

let pps = list ~sep:(any "@,@\n") pp
