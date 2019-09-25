let test expected () =
  Alcotest.(check string) "test 0" expected (Library.main ())

let suite =
  [
    ("Dummy passing test", `Quick, test "Hello, World!");
    ("Dummy failing test", `Quick, test "Bye, World!");
  ]

let () =
  Logs.set_level (Some Logs.Debug);
  Logs.set_reporter (Logs_fmt.reporter ());
  Alcotest.run "library" [ ("suite", suite) ]
