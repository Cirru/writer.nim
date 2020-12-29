
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
