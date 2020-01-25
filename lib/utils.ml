let exec cmd =
  let in_channel = Unix.open_process_in cmd in
  let line = input_line in_channel in
  match Unix.close_process_in in_channel with
  | WEXITED 0 -> Ok line
  | WEXITED n ->
      Error (`Msg (Fmt.strf "Command \"%s\" failed with return code %d" cmd n))
  | WSIGNALED _ | WSTOPPED _ ->
      Error (`Msg (Fmt.strf "Command \"%s\" was interrupted" cmd))

let sequence_commands cmds =
  List.fold_left
    (fun ret cmd ->
      match ret with
      | Error e -> Error e
      | Ok () -> (
          match Unix.system cmd with
          | WEXITED 0 -> Ok ()
          | WEXITED n ->
              Error
                (`Msg
                  (Fmt.strf "Command \"%s\" failed with return code %d" cmd n))
          | WSIGNALED _ | WSTOPPED _ ->
              Error (`Msg (Fmt.strf "Command \"%s\" was interrupted" cmd)) ))
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
