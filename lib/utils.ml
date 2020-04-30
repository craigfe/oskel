let ( >> ) f g x = g (f x)

module T2 = struct
  let map1 f (a, c) = (f a, c)

  let map2 f (a, b) = (a, f b)
end

module T3 = struct
  let map f (a1, a2, a3) = (f a1, f a2, f a3)
end

module Option = struct
  type 'a t = 'a option

  let get = function Some o -> o | None -> raise (Invalid_argument "None")

  let value opt ~default = match opt with Some o -> o | None -> default
end

module Result = struct
  type ('a, 'e) t = ('a, 'e) result

  let map f = function Ok o -> Ok (f o) | Error _ as e -> e

  let bind x f = match x with Ok o -> f o | Error _ as e -> e

  let errorf fmt = Format.kasprintf (fun msg -> Error (`Msg msg)) fmt

  module Infix = struct
    let ( >>= ) = bind

    let ( >>| ) x f = map f x

    let ( >=> ) f g x = bind (f x) g
  end

  module Syntax = struct
    let ( let* ) = bind

    let ( let+ ) x f = map f x
  end
end

module List = struct
  include List

  let rec filter_map f = function
    | [] -> []
    | x :: xs -> (
        match f x with
        | Some x -> x :: filter_map f xs
        | None -> filter_map f xs )

  module Infix = struct
    let ( >>| ) x f = List.map f x
  end

  let sequence_result list =
    let rec inner acc = function
      | [] -> Ok (List.rev acc)
      | Error e :: _ -> Error e
      | Ok o :: tl -> (inner [@ocaml.tailcall]) (o :: acc) tl
    in
    inner [] list
end

module Utils_unix = struct
  let ( let+ ) x f = Lwt.map f x

  let ( let* ) = Lwt.bind

  let exec cmd =
    let pipe_out, pipe_in = Lwt_unix.pipe () in
    let* process_status =
      Lwt_process.exec ~stderr:`Dev_null
        ~stdout:(`FD_move (Lwt_unix.unix_file_descr pipe_in))
        (Lwt_process.shell cmd)
    in
    let+ lines =
      Lwt_io.(of_fd ~mode:input) pipe_out
      |> Lwt_io.read_lines
      |> Lwt_stream.to_list
    in
    match process_status with
    | WEXITED 0 -> Ok lines
    | WEXITED 127 ->
        Error (`Command_not_found (String.split_on_char ' ' cmd |> List.hd))
    | WEXITED n ->
        Result.errorf "Command \"%s\" failed with return code %d" cmd n
    | WSIGNALED _ | WSTOPPED _ ->
        Result.errorf "Command \"%s\" was interrupted" cmd

  let execf fmt = Format.kasprintf exec ("@[<h>" ^^ fmt ^^ "@]")

  let sequence_commands cmds =
    List.fold_left
      (fun ret cmd ->
        match ret with
        | Error e -> Error e
        | Ok () -> (
            match Unix.system cmd with
            | WEXITED 0 -> Ok ()
            | WEXITED n ->
                Result.errorf "Command \"%s\" failed with return code %d" cmd n
            | WSIGNALED _ | WSTOPPED _ ->
                Result.errorf "Command \"%s\" was interrupted" cmd ))
      (Ok ()) cmds

  let print_to_file path printer =
    let channel = open_out path in
    let formatter = Format.formatter_of_out_channel channel in
    printer formatter;
    Format.pp_print_newline formatter ();
    close_out channel

  let rec mkdir_p path =
    try Unix.mkdir path 0o777 with
    | Unix.Unix_error (EEXIST, _, _) -> ()
    | Unix.Unix_error (ENOENT, _, _) ->
        let parent = Filename.dirname path in
        mkdir_p parent;
        Unix.mkdir path 0o777
end

module Utils_naming = struct
  let file_of_project = String.map (function '-' -> '_' | c -> c)

  let findlib_of_project = file_of_project >> String.capitalize_ascii
end
