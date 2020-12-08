
Cirru Writer in Nim
----

> Ported from ClojureScript version of writer.

### Usage

```nim
requires "https://github.com/Cirru/writer.nim"
```

```nim
import cirru_writer

# more information in types.nim
let xs: CirruWriterNode = toWriterList(%* [
  ["a", "b", ["c", ["c1", "c5", ["c3", "c4"]]], "d"]
])

writeCirruCode(xs)

writeCirruCode(xs, (useInline: true)) # for inline demo
```

### License

MIT
