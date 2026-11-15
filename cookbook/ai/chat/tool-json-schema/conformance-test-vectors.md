
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tool-json-schema-001 | object-shape, required-default-empty, empty-properties, sorted-keys-output | `object(properties: [:])` | Bytes decode to `{"properties":{},"required":[],"type":"object"}` with keys in that sorted order |
| tool-json-schema-002 | fragment-string, object-shape, properties-passthrough | `object(properties: ["x": string("x")])` (the schema used by `HostMCPServerTests`) | Decodes to an object whose `properties.x` is `{"description":"x","type":"string"}` |
| tool-json-schema-003 | fragment-integer, fragment-number, fragment-boolean | Call `integer("n")`, `number("n")`, `boolean("n")` | Each returns a two-key dictionary with `type` `integer`, `number`, `boolean` respectively and `description` `n` |
| tool-json-schema-004 | required-order-preserved | `object(properties: ["b": string("b"), "a": string("a")], required: ["b", "a"])` | `required` decodes as `["b", "a"]`; `properties` keys appear sorted `a`, `b` in the bytes |
| tool-json-schema-005 | required-not-checked-against-properties | `object(properties: [:], required: ["ghost"])` | `required` decodes as `["ghost"]`; no error |
| tool-json-schema-006 | sorted-keys-output | Call `object` twice with the same multi-property input | The two `Data` values are byte-equal |
| tool-json-schema-007 | fragment-description-verbatim | `string("")` | `description` is the empty string, key still present |
| tool-json-schema-008 | object-shape | `object(properties: ["u": string("a url")], required: ["u"])` | Top-level keys are exactly `properties`, `required`, `type`; `required` is `["u"]` |

The schema is exercised indirectly as a fixture by `CompositeChatToolSourceTests`, `HostMCPServerTests`, `HostMCPServerDrainTests`, `LocalChatSessionTests`, `MCPHTTPEndpointTests` and `PersonaTerminalChatToolsTests`; `ToolJSONSchemaConformanceTests` asserts its output bytes directly, one test per vector.

