
type
  CirruWriterNodeKind* = enum
    writerItem,
    writerList

  CirruWriterNode* = object
    line*: int
    column*: int
    case kind*: CirruWriterNodeKind
    of writerItem:
      item*: string
    of writerList:
      list*: seq[CirruWriterNode]

type CirruWriterError* = object of ValueError
  discard

type WriterNodeKind* = enum
  writerKindNil,
  writerKindLeaf,
  writerKindSimpleExpr,
  writerKindBoxedExpr,
  writerKindExpr,

proc `$`*(xs: CirruWriterNode): string =
  if xs.kind == writerItem:
    result = xs.item
  else:
    for idx, item in xs.list:
      if idx > 0:
        result = result & " "
      if item.kind == writerItem:
        result = result & item.item
      else:
        result = result & "(" & $(item) & ")"

proc isSimpleExpr*(xs: CirruWriterNode): bool =
  if xs.kind == writerList:
    result = true
    for x in xs.list:
      if x.kind != writerItem:
        result = false
  else:
    result = false
