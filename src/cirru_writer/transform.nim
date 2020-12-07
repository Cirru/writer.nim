
import ./types

proc isSimpleExpr*(xs: CirruWriterNode): bool =
  if xs.kind == writerList:
    result = true
    for x in xs.list:
      if x.kind != writerItem:
        result = false
  else:
    result = false

proc transformComma*(xs: CirruWriterNode): CirruWriterNode =
  discard

proc transformDollar*(xs: CirruWriterNode): CirruWriterNode =
  discard
