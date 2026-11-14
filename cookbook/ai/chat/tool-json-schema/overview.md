
`ToolJSONSchema` is a caseless `enum` of static helpers that build the `parametersJSONSchema` value of a `ToolDefinition`. Its doc comment gives the reason: "One place, so every tool source spells an object schema the same way." A tool source describes each argument with one of four fragment helpers (`string`, `integer`, `number`, `boolean`), then wraps the fragments with `object(properties:required:)`, which returns the finished schema as UTF-8 JSON `Data`.

