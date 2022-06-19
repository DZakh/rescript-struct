open Ava

type singleFieldRecord = {foo: string}
type multipleFieldsRecord = {boo: string, zoo: string}
type user = {name: string, email: string, age: int}
type nestedRecord = {nested: singleFieldRecord}
type optionalNestedRecord = {singleFieldRecord: option<singleFieldRecord>}

test("Successfully parses record with single field", t => {
  let value = {foo: "bar"}
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~parser=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with multiple fields", t => {
  let value = {boo: "bar", zoo: "jee"}
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~parser=((boo, zoo)) => {boo: boo, zoo: zoo}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with mapped field names", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~parser=((name, email, age)) => {name: name, email: email, age: age}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with optional nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~parser=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~parser=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with optional nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~parser=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~parser=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with deprecated nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.deprecated(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~parser=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~parser=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses record with deprecated nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.deprecated(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~parser=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~parser=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Successfully parses array of records", t => {
  let value = [{foo: "bar"}, {foo: "baz"}]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~parser=foo => {foo: foo}->Ok, ()),
  )

  t->Assert.deepEqual(any->S.parseWith(struct), Ok(value), ())
})

test("Throws for a Record factory without either a parser, or a serializer", t => {
  t->Assert.throws(() => {
    S.record1(~fields=("any", S.string()), ())->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="For a Record struct factory either a parser, or a serializer is required",
    (),
  ), ())
})

test("Fails to parse when parser isn't provided", t => {
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~serializer=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Struct parser is missing"),
    (),
  )
})

test("Fails to parse when nested record parser isn't provided", t => {
  let any = %raw(`{nested: {foo: "bar"}}`)

  let struct = S.record1(
    ~fields=("nested", S.record1(~fields=("foo", S.string()), ~serializer=({foo}) => foo->Ok, ())),
    ~parser=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at [nested]. Reason: Struct parser is missing`),
    (),
  )
})

test("Fails to parse when user returns error in a root record parser", t => {
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~parser=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: User error"),
    (),
  )
})

test("Fails to parse when user returns error in a nested record parser", t => {
  let any = %raw(`{nested: {foo: "bar"}}`)

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~parser=_ => Error("User error"), ()),
    ),
    ~parser=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.parseWith(~mode=Unsafe, struct),
    Error(`[ReScript Struct] Failed parsing at [nested]. Reason: User error`),
    (),
  )
})

test("Successfully serializes unknown record with single field", t => {
  let value = {foo: "bar"}
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~serializer=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown record with multiple fields", t => {
  let value = {boo: "bar", zoo: "jee"}
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~serializer=({boo, zoo}) => (boo, zoo)->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown record with mapped field", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~serializer=({name, email, age}) => (name, email, age)->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown record with optional nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~serializer=({foo}) => foo->Ok, ()),
      ),
    ),
    ~serializer=({singleFieldRecord}) => singleFieldRecord->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown record with optional nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{"singleFieldRecord":undefined}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~serializer=({foo}) => foo->Ok, ()),
      ),
    ),
    ~serializer=({singleFieldRecord}) => singleFieldRecord->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Successfully serializes unknown array of records", t => {
  let value = [{foo: "bar"}, {foo: "baz"}]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~serializer=({foo}) => foo->Ok, ()),
  )

  t->Assert.deepEqual(value->S.serializeWith(struct), Ok(any), ())
})

test("Fails to serialize record when serializer isn't provided", t => {
  let value = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~parser=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: Struct serializer is missing"),
    (),
  )
})

test("Fails to serialize nested record when serializer isn't provided", t => {
  let value = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=("nested", S.record1(~fields=("foo", S.string()), ~parser=foo => {foo: foo}->Ok, ())),
    ~serializer=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error(`[ReScript Struct] Failed serializing at [nested]. Reason: Struct serializer is missing`),
    (),
  )
})

test("Fails to serialize when user returns error in a root record serializer", t => {
  let value = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~serializer=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error("[ReScript Struct] Failed serializing at root. Reason: User error"),
    (),
  )
})

test("Fails to serialize when user returns error in a nested record serializer", t => {
  let value = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~serializer=_ => Error("User error"), ()),
    ),
    ~serializer=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    value->S.serializeWith(struct),
    Error(`[ReScript Struct] Failed serializing at [nested]. Reason: User error`),
    (),
  )
})

test(
  "Successfully parses a record with fields mapping and serializes it back to the initial state",
  t => {
    let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

    let struct = S.record3(
      ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
      ~parser=((name, email, age)) => {name: name, email: email, age: age}->Ok,
      ~serializer=({name, email, age}) => (name, email, age)->Ok,
      (),
    )

    t->Assert.deepEqual(
      any->S.parseWith(struct)->Belt.Result.map(record => record->S.serializeWith(struct)),
      Ok(Ok(any)),
      (),
    )
  },
)

test("Fails to parse record", t => {
  let struct = S.record1(~fields=("FOO", S.string()), ~parser=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(
    Js.Json.string("string")->S.parseWith(struct),
    Error("[ReScript Struct] Failed parsing at root. Reason: Expected Record, got String"),
    (),
  )
})

test("Fails to parse record item when it's not present", t => {
  let struct = S.record1(~fields=("FOO", S.string()), ~parser=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(
    %raw(`{}`)->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at [FOO]. Reason: Expected String, got Option`),
    (),
  )
})

test("Fails to parse record item when it's not valid", t => {
  let struct = S.record1(~fields=("FOO", S.string()), ~parser=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(
    %raw(`{FOO:123}`)->S.parseWith(struct),
    Error(`[ReScript Struct] Failed parsing at [FOO]. Reason: Expected String, got Float`),
    (),
  )
})
