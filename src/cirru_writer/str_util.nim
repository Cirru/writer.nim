
proc isADigit*(c: char): bool =
  let n = ord(c)
  # ascii table https://tool.oschina.net/commons?type=4
  n >= 48 and n <= 57

proc isALetter*(c: char): bool =
  let n = ord(c)
  if n >= 65 and n <= 90:
    return true
  if n >= 97 and n <= 122:
    return true
  return false

# based on https://github.com/nim-lang/Nim/blob/version-1-4/lib/pure/strutils.nim#L2322
# strutils.escape turns Chinese into longer something "\xE6\xB1\x89",
# so... this is a simplified one according to Cirru Parser
proc escapeCirruStr*(s: string, prefix = "\"", suffix = "\""): string =
  result = newStringOfCap(s.len + s.len shr 2)
  result.add(prefix)
  for c in items(s):
    case c
    # disabled since not sure if useful for Cirru
    # of '\0'..'\31', '\127'..'\255':
    #   add(result, "\\x")
    #   add(result, toHex(ord(c), 2))
    of '\\': add(result, "\\\\")
    of '\"': add(result, "\\\"")
    of '\n': add(result, "\\n")
    of '\t': add(result, "\\t")
    else: add(result, c)
  add(result, suffix)
