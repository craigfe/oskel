let project s =
  let s = String.trim s in
  if String.length s = 0 then Error (`Msg "Project name cannot be empty")
  else if String.contains s ' ' then
    Error (`Msg "Project name cannot contain spaces")
  else Ok s
