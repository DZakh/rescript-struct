open Ava

test("Successfully parses valid data", t => {
  let struct = S.array(S.int())->S.Array.max(1)

  t->Assert.deepEqual([1]->S.parseWith(struct), Ok([1]), ())
  t->Assert.deepEqual([]->S.parseWith(struct), Ok([]), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.array(S.int())->S.Array.max(1)

  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.parseWith(struct),
    Error({
      code: OperationFailed("Array must be 1 or fewer items long"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.array(S.int())->S.Array.max(1)

  t->Assert.deepEqual([1]->S.serializeWith(struct), Ok(%raw(`[1]`)), ())
  t->Assert.deepEqual([]->S.serializeWith(struct), Ok(%raw(`[]`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.array(S.int())->S.Array.max(1)

  t->Assert.deepEqual(
    [1, 2, 3, 4]->S.serializeWith(struct),
    Error({
      code: OperationFailed("Array must be 1 or fewer items long"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.array(S.int())->S.Array.max(~message="Custom", 1)

  t->Assert.deepEqual(
    [1, 2]->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
