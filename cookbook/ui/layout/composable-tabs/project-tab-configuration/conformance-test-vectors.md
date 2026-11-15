
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| project-tab-configuration-001 | arrangement-only, memberwise-construction | Build a configuration from a two-leaf horizontal split | Its arrangement equals that split tree |
| project-tab-configuration-002 | arrangement-optional | Build a configuration with no arrangement | Its arrangement is absent |
| project-tab-configuration-003 | no-edges | Inspect the configuration's stored fields | The arrangement is the only field; no edge set is present |
| project-tab-configuration-004 | immutable-value | Hand a configuration from one concurrency domain to another | It compiles and arrives unchanged; its arrangement cannot be reassigned |
