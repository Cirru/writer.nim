
import re
import strutils
import sequtils

import cirru_writer/types
import cirru_writer/transform
import cirru_writer/from_json

export toWriterList, `$`, CirruWriterNode, CirruWriterNodeKind

let allowedChars = "-~_@#$&%!?^*=+|\\/<>[]{}.,:;'"

proc isBoxed(xs: CirruWriterNode): bool =
  if xs.kind == writerList:
    for x in xs.list:
      if x.kind == writerItem:
        return false
    return true
  else:
    return false

proc isSimpleChar(x: char): bool =
  ($x).match(re"^[a-zA-Z0-9]$")

proc isCharAllowed(x: char): bool =
  if x.isSimpleChar():
    return true
  if allowedChars.contains(x):
    return true
  return false

let charClose = ')'
let charOpen = '('
let charSpace = ' '

proc generateLeaf(xs: CirruWriterNode): string =
  if xs.kind == writerList:
    if xs.list.len == 0:
      return "()"
    else:
      raise newException(CirruWriterError, "Unexpect list in leaf")
  else:
    var allAllowed = true
    for x in xs.item:
      if not x.isCharAllowed:
        allAllowed = false
        break
    if allAllowed:
      return xs.item
    else:
      return xs.item.escape

proc generateInlineExpr(xs: CirruWriterNode): string =
  result = $charOpen

  if xs.kind == writerList:
    for idx, x in xs.list:
      if idx > 0:
        result = result & charSpace
      let childForm = if x.kind == writerItem:
        x.generateLeaf()
      else:
        x.generateInlineExpr()
      result = result & childForm
  else:
    raise newException(CirruWriterError, "Unexpect token in gen list")

  result = result & charClose

proc renderSpaces(n: int): string =
  for i in 0..<n:
    result = result & "  "

proc renderNewline(n: int): string =
  "\n" & renderSpaces(n)

type WriterTreeOptions = tuple[useInline: bool]

proc getNodeKind(cursor: CirruWriterNode): WriterNodeKind =
  if cursor.kind == writerItem:
    writerKindLeaf
  else:
    if cursor.list.len == 0:
      writerKindLeaf
    elif isSimpleExpr(cursor):
      writerKindSimpleExpr
    elif isBoxed(cursor):
      writerKindBoxedExpr
    else:
      writerKindExpr

proc generateTree(xs: CirruWriterNode, insistHead: bool, options: WriterTreeOptions, level: int): string =
  var prevKind = writerKindNil

  if xs.kind == writerItem:
    raise newException(CirruWriterError, "expects a list")

  for idx, cursor in xs.list:
    let kind = getNodeKind(cursor)

    let child = if kind == writerKindLeaf:
      generateLeaf(cursor)
    else:
      if idx == 0 and insistHead:
        generateInlineExpr(cursor)
      else:
        case kind
          of writerKindSimpleExpr:
            if prevKind == writerKindLeaf:
              generateInlineExpr(cursor)
            elif options.useInline and prevKind == writerKindSimpleExpr:
              charSpace & generateInlineExpr(cursor)
            else:
              renderNewline(level + 1) & generateTree(cursor, false, options, level + 1)
          of writerKindExpr:
            renderNewline(level + 1) & generateTree(cursor, false, options, level + 1)
          of writerKindBoxedExpr:
            let spaces = if prevKind == writerKindLeaf or prevKind == writerKindSimpleExpr or prevKind == writerKindNil:
              ""
            else:
              renderNewline(level + 1)
            spaces & generateTree(cursor, prevKind == writerKindBoxedExpr or prevKind == writerKindExpr, options, level + 1)
          else:
            raise newException(CirruWriterError, "Not handled yet")

    if prevKind == writerKindLeaf:
      if kind == writerKindLeaf or kind == writerKindSimpleExpr:
        result = result & charSpace
    elif prevKind == writerKindLeaf or prevKind == writerKindSimpleExpr:
      if kind == writerKindLeaf:
        result = result & charSpace
    result = result & child

    if options.useInline and kind == writerKindSimpleExpr:
      if prevKind == writerKindLeaf or prevKind == writerKindSimpleExpr:
        prevKind = writerKindSimpleExpr
      else:
        prevKind = writerKindExpr
    else:
      prevKind = kind

proc generateStatements(xs: CirruWriterNode, options: WriterTreeOptions): string =
  let xs1 = xs.transformComma()
  # echo "xs1: ", xs1
  let xs2 = xs1.transformDollar()
  # echo "xs2: ", xs2
  if xs2.kind == writerItem:
    raise newException(CirruWriterError, "Unexpected item")
  xs2.list.map(proc(x: CirruWriterNode): string =
    "\n" & generateTree(x, true, options, 0) & "\n"
  ).join("")

proc writeCirruCode*(xs: CirruWriterNode, options: WriterTreeOptions = (useInline: false)): string =
  generateStatements(xs, options)

