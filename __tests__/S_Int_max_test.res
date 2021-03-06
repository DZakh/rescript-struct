open Ava

test("Successfully parses valid data", t => {
  let struct = S.int()->S.Int.max(1)

  t->Assert.deepEqual(1->S.parseWith(struct), Ok(1), ())
  t->Assert.deepEqual(-1->S.parseWith(struct), Ok(-1), ())
})

test("Fails to parse invalid data", t => {
  let struct = S.int()->S.Int.max(1)

  t->Assert.deepEqual(
    1234->S.parseWith(struct),
    Error({
      code: OperationFailed("Number must be lower than or equal to 1"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes valid value", t => {
  let struct = S.int()->S.Int.max(1)

  t->Assert.deepEqual(1->S.serializeWith(struct), Ok(%raw(`1`)), ())
  t->Assert.deepEqual(-1->S.serializeWith(struct), Ok(%raw(`-1`)), ())
})

test("Fails to serialize invalid value", t => {
  let struct = S.int()->S.Int.max(1)

  t->Assert.deepEqual(
    1234->S.serializeWith(struct),
    Error({
      code: OperationFailed("Number must be lower than or equal to 1"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Returns custom error message", t => {
  let struct = S.int()->S.Int.max(~message="Custom", 1)

  t->Assert.deepEqual(
    12->S.parseWith(struct),
    Error({
      code: OperationFailed("Custom"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})
