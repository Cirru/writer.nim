
type
  WriterNodeKind* = enum
    writerItem,
    writerList

  CirruWriterNode* = object
    line*: int
    column*: int
    case kind*: WriterNodeKind
    of writerItem:
      item*: string
    of writerList:
      list*: seq[CirruWriterNode]

type CirruWriterError* = object of ValueError
  discard
