open Ava

test("Successfully parses valid data", t => {
  let struct = S.array(S.int())->S.Array.length(1)

  t->Assert.deepEqual([1]->S.parseWith(struct), Ok([1]), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.array(S.int())->S.Array.length(1)

  t->Assert.deepEqual(
    []->S.parseWith(struct),
    Error({
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.parseWith(struct),
    Error({
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.array(S.int())->S.Array.length(1)

  t->Assert.deepEqual([1]->S.serializeWith(struct), Ok(%raw(`[1]`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.array(S.int())->S.Array.length(1)

  t->Assert.deepEqual(
    []->S.serializeWith(struct),
    Error({
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.serializeWith(struct),
    Error({
      code: OperationFailed("Array must be exactly 1 items long"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.array(S.int())->S.Array.length(~message="Custom", 1)

  t->Assert.deepEqual(
    []->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
