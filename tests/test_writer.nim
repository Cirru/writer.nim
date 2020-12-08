
import json
import unittest

import cirru_writer

test "can add":
  check 5 + 5 == 10
  let data = toWriterList(%* [
    ["a", "b", ["c", ["c1", "c5", ["c3", "c4"]]], "d"]
  ])
  echo writeCirruCode(data)
