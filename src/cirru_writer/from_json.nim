
import json

import ./types

proc toWriterList*(xs: JsonNode): CirruWriterNode =
  case xs.kind
  of JArray:
    result = CirruWriterNode(kind: writerList, list: @[])
    for x in xs.elems:
      result.list.add x.toWriterList

  of JString:
    result = CirruWriterNode(kind: writerItem, item: xs.getStr)

  else:
    raise newException(CirruWriterError, "unexpected type to gen list")