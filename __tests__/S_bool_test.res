open Ava

module Common = {
  let value = true
  let any = %raw(`true`)
  let wrongAny = %raw(`"Hello world!"`)
  let factory = () => S.bool()

  test("Successfully parses in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
  })

  test("Successfully parses without validation in Migration mode", t => {
    let struct = factory()

    t->Assert.deepEqual(wrongAny->S.parseWith(~mode=Migration, struct), Ok(wrongAny), ())
  })

  test("Fails to parse in Safe mode", t => {
    let struct = factory()

    t->Assert.deepEqual(
      wrongAny->S.parseWith(struct),
      Error({
        code: UnexpectedType({expected: "Bool", received: "String"}),
        operation: Parsing,
        path: [],
      }),
      (),
    )
  })

  test("Successfully serializes", t => {
    let struct = factory()

    t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
  })
}

test("Parses bool when JSON is true", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(true)->S.parseWith(struct), Ok(true), ())
})

test("Parses bool when JSON is false", t => {
  let struct = S.bool()

  t->Assert.deepEqual(Js.Json.boolean(false)->S.parseWith(struct), Ok(false), ())
})
