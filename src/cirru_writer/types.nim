
type
  WriterNodeKind* = enum
    writerItem,
    writerList

  WriterNode* = object
    line*: int
    column*: int
    case kind*: WriterNodeKind
    of writerItem:
      item*: string
    of writerList:
      list*: seq[WriterNode]
