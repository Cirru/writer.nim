
import json
import unittest
import strutils

import edn

import cirru_writer

proc toWriterList(xs: EdnNode): CirruWriterNode =
  case xs.kind
  of EdnVector:
    result = CirruWriterNode(kind: writerList, list: @[])
    for x in xs.vec:
      result.list.add(x.toWriterList)
  of EdnString:
    result = CirruWriterNode(kind: writerItem, item: xs.str)
  else:
    echo xs.kind, xs.num
    raise newException(ValueError, "unexpected EDN type for now")

let caseNames = @[
  "demo",
  "double-nesting",
  "fold-vectors",
  "folding",
  "html",
  "indent",
  "inline-let",
  "inline-mode",
  "inline-simple",
  "line",
  "nested-2",
  "parentheses",
  "quote",
  "spaces",
  "unfolding",
]

test "can add":
  check 5 + 5 == 10
  let data = toWriterList(%* [
    ["a", "b", ["c", ["c1", "c5", ["c3", "c4"]]], "d"]
  ])
  # echo writeCirruCode(data)

  for name in caseNames:
    let content = readFile("tests/ast/" & name & ".edn")
    let v = read(content)
    let xs = v.toWriterList
    let target = readFile("tests/cirru/" & name & ".cirru")

    echo "checking: ",  name
    check xs.writeCirruCode.strip.escape == target.strip.escape
    echo ""

  # let ednValue = read("[\"a\" \"b\" \"c\"]")
  # echo ednValue.toWriterList
