
import strutils
import sequtils

import cirru_writer/types
import cirru_writer/from_json
import cirru_writer/str_util

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
  x.isADigit() or x.isALetter()

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
      return escapeCirruStr(xs.item)

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

proc generateTree(xs: CirruWriterNode, insistHead: bool, options: WriterTreeOptions, level: int, inTail: bool): string =
  var prevKind = writerKindNil
  var bended = false

  if xs.kind == writerItem:
    raise newException(CirruWriterError, "expects a list")

  for idx, cursor in xs.list:
    let kind = getNodeKind(cursor)
    let nextLevel = level + 1
    let childInsistHead = prevKind == writerKindBoxedExpr or prevKind == writerKindExpr
    let atTail = idx != 0 and
      not inTail and
      prevKind == writerKindLeaf and
      idx == xs.list.len - 1 and
      cursor.kind == writerList

    let child = if atTail:
      if cursor.list.len == 0:
        "$"
      else:
        "$ " & generateTree(cursor, false, options, if bended: nextLevel else: level, atTail)
    elif kind == writerKindLeaf:
      generateLeaf(cursor)
    elif idx == 0 and insistHead:
      generateInlineExpr(cursor)
    elif kind == writerKindSimpleExpr:
      if prevKind == writerKindLeaf:
        generateInlineExpr(cursor)
      elif options.useInline and prevKind == writerKindSimpleExpr:
        " " & generateInlineExpr(cursor)
      else:
        renderNewline(nextLevel) & generateTree(cursor, childInsistHead, options, nextLevel, false)
    elif kind == writerKindExpr:
      renderNewline(nextLevel) & generateTree(cursor, childInsistHead, options, nextLevel, false)
    elif kind == writerKindBoxedExpr:
      let content = generateTree(cursor, childInsistHead, options, nextLevel, false)
      if prevKind == writerKindNil or prevKind == writerKindLeaf or prevKind == writerKindSimpleExpr:
        content
      else:
        renderNewline(nextLevel) & content
    else:
      raise newException(ValueError, "Unpected condition")

    let chunk = if atTail:
      " " & child
    elif prevKind == writerKindLeaf and kind == writerKindLeaf:
      " " & child
    elif prevKind == writerKindLeaf and kind == writerKindSimpleExpr:
      " " & child
    elif prevKind == writerKindSimpleExpr and kind == writerKindLeaf:
      " " & child
    elif kind == writerKindLeaf and (prevKind == writerKindBoxedExpr or prevKind == writerKindExpr):
      renderNewline(nextLevel) & ", " & child
    else:
      child

    result = result & chunk


    # update writer states

    prevKind = if kind == writerKindSimpleExpr:
      if idx == 0 and insistHead:
        writerKindSimpleExpr
      elif options.useInline:
        if prevKind == writerKindLeaf or prevKind == writerKindSimpleExpr:
          writerKindSimpleExpr
        else:
          writerKindExpr
      else:
        if prevKind == writerKindLeaf:
          writerKindSimpleExpr
        else:
          writerKindExpr
    else:
      kind

    if not bended:
      if kind == writerKindExpr or kind == writerKindBoxedExpr:
        bended = true

proc generateStatements(xs: CirruWriterNode, options: WriterTreeOptions): string =
  if xs.kind == writerItem:
    raise newException(CirruWriterError, "Unexpected item")
  xs.list.map(proc(x: CirruWriterNode): string =
    "\n" & generateTree(x, true, options, 0, false) & "\n"
  ).join("")

proc writeCirruCode*(xs: CirruWriterNode, options: WriterTreeOptions = (useInline: false)): string =
  generateStatements(xs, options)
