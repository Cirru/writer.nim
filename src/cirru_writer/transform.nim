
import ./types

proc isSimpleExpr*(xs: CirruWriterNode): bool =
  if xs.kind == writerList:
    result = true
    for x in xs.list:
      if x.kind != writerItem:
        result = false
  else:
    result = false

proc vecAdd(xs, ys: seq[CirruWriterNode]): seq[CirruWriterNode] =
  result = xs
  for y in ys:
    result.add y

let commaNode = CirruWriterNode(kind: writerItem, item: ",")
let dollarNode = CirruWriterNode(kind: writerItem, item: "$")

proc transformComma*(xs: CirruWriterNode): CirruWriterNode =
  if xs.kind == writerItem:
    raise newException(CirruWriterError, "expects list to transform")

  result = CirruWriterNode(kind: writerList, list: @[])
  var chunk: seq[CirruWriterNode]
  var prevKind = writerKindNil

  for idx, cursor in xs.list:
    let kind = if cursor.kind == writerItem or cursor.list.len == 0:
      writerKindLeaf
    elif prevKind == writerKindLeaf and isSimpleExpr(cursor):
      writerKindSimpleExpr
    else:
      writerKindExpr
    if kind == writerKindLeaf and (prevKind == writerKindExpr or chunk.len > 0):
      chunk.add cursor
    else:
      # echo "chunk inside: ", chunk
      if chunk.len > 0:
        result.list.add CirruWriterNode(kind: writerList, list: vecAdd(@[commaNode], chunk))
        chunk = @[]
      if cursor.kind == writerItem:
        result.list.add cursor
      else:
        result.list.add transformComma(cursor)
    prevKind = kind

  # echo "at end: ", chunk

  if chunk.len > 0:
    result.list.add CirruWriterNode(kind: writerList, list: vecAdd(@[commaNode], chunk))

proc transformDollar*(xs: CirruWriterNode, atDollar: bool = false): CirruWriterNode =
  result = CirruWriterNode(kind: writerList, list: @[])
  var prevKind = writerKindNil
  if xs.kind == writerItem:
    result = xs
  else:
    for idx, cursor in xs.list:
      let kind = if cursor.kind == writerItem:
        writerKindLeaf
      else:
        writerKindExpr
      let useDollarTail = idx > 0 and prevKind == writerKindLeaf and
        not atDollar and cursor.kind == writerList and idx == xs.list.len - 1
      if useDollarTail:
        result.list.add dollarNode
        let children = transformDollar(cursor, true)
        if children.kind == writerItem:
          raise newException(CirruWriterError, "expects list from transform")
        for child in children.list:
          result.list.add child
      else:
        if cursor.kind == writerItem:
          result.list.add cursor
        else:
          result.list.add transformDollar(cursor, false)
      prevKind = kind
  # echo "transform result: ", result
