# Package

version       = "0.1.1"
author        = "jiyinyiyong"
description   = "Cirru writer in Nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.6"
requires "https://github.com/rosado/edn.nim"

task t, "run test once":
  exec "nim c --verbosity:0 --hints:off -r tests/test_writer.nim"
