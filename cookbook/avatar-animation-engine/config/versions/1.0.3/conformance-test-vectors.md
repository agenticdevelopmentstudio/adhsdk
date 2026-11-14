
| # | Requirement | Input | Expected | Source |
|---|---|---|---|---|
| 1 | schema-version-required | A rig file with `schemaVersion: 2` while the loader expects `1` | Rejects, naming the file and both version numbers | `ConfigTests.swift` schema-version tests; `load.test.ts` schema version describe block |
| 2 | duplicate-node-id-rejected | Two rig nodes both authored with id `"torso"` | Rejects on both platforms; Swift message contains "two nodes share the id", TS message contains "duplicate node id" | `ConfigTests.swift` duplicate id test; `load.test.ts` duplicate id test |
| 3 | palette-hex-format | `character.palette` entry `"ink1": "notahex"` | Rejects, naming the palette key and value | `ConfigTests.swift` `isLoadableHex` / palette tests |
| 4 | shaped-node-requires-ink | A `path`-shaped rig node with `ink: null` | Rejects, naming the node | `ConfigTests.swift` shape/ink tests |
| 5 | bend-response-damping | `respond("antennaLeft.bend", 10)` where the bend's `inwardSign` matches the value's sign and damping is configured | Returns a damped value; `load.test.ts` asserts `toBeCloseTo(7.2, 10)` for this exact channel/value pair | `load.test.ts` bend-damping test |
| 6 | command-signature-agreement | Two poses driving the same `.shape` channel with different path command signatures (e.g. one `M L L`, one `M C C`) | Rejects, naming both conflicting poses/sources | `ConfigTests.swift` all-pairs path-kind tests |
| 7 | promotion-source-target-kind | A promote step from an `M L L` family to an `M C C C C` family (4 curves for 2 lines, a whole multiple) accepted; a promote step to `M C C C` (3 curves for 2 lines) rejected | First accepted, second rejected naming the mismatched segment counts | `ConfigTests.swift` promotion tests |
| 8 | timeline-duration-floor | A timeline with `duration: 1000` but a step at `at: 1200, duration: 0` | Rejects, since the last step ends after the declared duration | `ConfigTests.swift` timeline duration tests |
| 9 | pair-fields-exactly-two | `idleFidget.rearm.gapMs: [500]` (one element) | Rejects for having fewer than two numbers | `ConfigTests.swift` pair-field tests (rearm.gapMs) |
| 10 | mood-effect-branch-list-defined | An effect with `branch: ["twitch"]` where `twitch: []` is authored as an empty array | Accepted — an authored empty list is a defined branch target, distinct from an absent one | `ConfigTests.swift` comment/test: "still accepts an effect whose branch list is authored empty" |
| 11 | ladder-three-rungs-required | `behavior.ladder.moods` supplying only `"active"` and `"bored"` (missing `"asleep"`) | Rejects, naming the missing rung | `ConfigTests.swift` ladder tests |
| 12 | ink-late-binding-target | An ink `color: "@missingNode"` where no rig node has id `"missingNode"` | Rejects, naming the unresolved late-bound reference | `ConfigTests.swift` / `load.test.ts` ink late-binding tests |
| 13 | variant-shape-patch-target-validated | A variant shape patch targeting a node that already has a `.shape` rest channel (is morphable) | Rejects, since patching a channel-driven shape would be overwritten every frame | `ConfigTests.swift` variant patch tests |
| 14 | fallback-mood-has-sayings | `sayings` omitting an entry for the pose named at `ladder.moods["active"]` | Rejects, naming the missing fallback mood | `ConfigTests.swift` sayings tests |
| 15 | load-does-not-mutate-caller-input | Calling `loadConfig` twice with the identical shared `RawFiles` object reference | Both calls succeed independently and the caller's original object is unchanged after either call | `load.test.ts` "loads olylo" fixture tests |

