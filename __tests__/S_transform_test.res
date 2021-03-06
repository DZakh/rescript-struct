open Ava

test("Parses unknown primitive with transformation to the same type", t => {
  let any = %raw(`"  Hello world!"`)
  let transformedValue = "Hello world!"

  let struct = S.string()->S.transform(~parser=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(transformedValue), ())
})

test("Parses unknown primitive with transformation to another type", t => {
  let any = %raw(`123`)
  let transformedValue = 123.

  let struct = S.int()->S.transform(~parser=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(transformedValue), ())
})

test("Throws for a Transformed Primitive factory without either a parser, or a serializer", t => {
  t->Assert.throws(() => {
    S.string()->S.transform()->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message=String("For a struct factory Transform either a parser, or a serializer is required"),
    (),
  ), ())
})

test("Fails to parse primitive with transform when parser isn't provided", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~serializer=value => value->Ok, ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: MissingParser,
      path: [],
      operation: Parsing,
    }),
    (),
  )
})

test("Fails to parse when user returns error in a Transformed Primitive parser", t => {
  let any = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~parser=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes primitive with transformation to the same type", t => {
  let value = "  Hello world!"
  let transformedAny = %raw(`"Hello world!"`)

  let struct = S.string()->S.transform(~serializer=value => value->Js.String2.trim->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(transformedAny), ())
})

test("Successfully serializes primitive with transformation to another type", t => {
  let value = 123
  let transformedAny = %raw(`123`)

  let struct = S.float()->S.transform(~serializer=value => value->Js.Int.toFloat->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(transformedAny), ())
})

test("Transformed Primitive serializing fails when serializer isn't provided", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~parser=value => value->Ok, ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error({
      code: MissingSerializer,
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Fails to serialize when user returns error in a Transformed Primitive serializer", t => {
  let value = "Hello world!"

  let struct = S.string()->S.transform(~serializer=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test("Transform operations applyed in the right order when parsing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.transform(~parser=_ => Error("First transform"), ())
    ->S.transform(~parser=_ => Error("Second transform"), ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Transform operations applyed in the right order when serializing", t => {
  let any = %raw(`123`)

  let struct =
    S.int()
    ->S.transform(~serializer=_ => Error("Second transform"), ())
    ->S.transform(~serializer=_ => Error("First transform"), ())

  t->Assert.deepEqual(
    any->S.serializeWith(struct),
    Error({
      code: OperationFailed("First transform"),
      operation: Serializing,
      path: [],
    }),
    (),
  )
})

test(
  "Successfully parses a Transformed Primitive and serializes it back to the initial state",
  t => {
    let any = %raw(`123`)

    let struct =
      S.int()->S.transform(
        ~parser=int => int->Js.Int.toFloat->Ok,
        ~serializer=value => value->Belt.Int.fromFloat->Ok,
        (),
      )

    t->Assert.deepEqual(
      any
      ->S.parseWith(~mode=Migration, struct)
      ->Belt.Result.map(record => record->S.serializeWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)
