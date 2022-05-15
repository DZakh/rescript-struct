open Ava

module Common = {
  let any = %raw(`true`)
  let factory = () => S.never()

  test("Successfully constructs without validation. Note: Use S.parseWith instead", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.constructWith(struct), Ok(any), ())
  })

  test("Successfully destructs", t => {
    let struct = factory()

    t->Assert.deepEqual(any->S.destructWith(struct), Ok(any), ())
  })

  test("Fails to parse", t => {
    let struct = factory()

    t->Assert.deepEqual(
      any->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Never, got Bool"),
      (),
    )
  })
}

module RecordField = {
  type record = {key: string}

  test("Fails to parse a record with Never field", t => {
    let struct = S.record2(
      ~fields=(("key", S.string()), ("oldKey", S.never())),
      ~constructor=((key, _oldKey)) => {key: key}->Ok,
      (),
    )

    t->Assert.deepEqual(
      %raw(`{"key":"value"}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["oldKey"]. Reason: Expected Never, got Option`),
      (),
    )
  })

  test("Successfully parses a record with Never field when it's optional and not present", t => {
    let struct = S.record2(
      ~fields=(
        ("key", S.string()),
        (
          "oldKey",
          S.deprecated(~message="We stopped using the field from the v0.9.0 release", S.never()),
        ),
      ),
      ~constructor=((key, _oldKey)) => {key: key}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{"key":"value"}`)->S.parseWith(struct), Ok({key: "value"}), ())
  })
}