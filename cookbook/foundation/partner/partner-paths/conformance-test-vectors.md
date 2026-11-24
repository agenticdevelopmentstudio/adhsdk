
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-paths-001 | mcp-config-file, partner-directory | `home` `/h`, `token` `tok`; read `mcpConfig.path`. | `/h/.tok/partner/mcp.json` (test: pathsDeriveFromHomeAndToken). |
| partner-paths-002 | skill-file, skills-directory | `home` `/h`, `token` `tok`; read `skillFile(jobID: "x").path`. | `/h/.claude/skills/adkitchen-partner-x/SKILL.md` (test: pathsDeriveFromHomeAndToken). |
| partner-paths-003 | partner-directory | `home` `/h`, `token` `tok`; read `directory.path`. | `/h/.tok/partner`. |
| partner-paths-004 | system-prompt-file, jobs-directory, reviews-directory | `home` `/h`, `token` `tok`. | `systemPrompt.path` is `/h/.tok/partner/system-prompt.md`; `jobsDirectory.path` is `/h/.tok/partner/jobs`; `reviewsDirectory.path` is `/h/.tok/partner/reviews`. |
| partner-paths-005 | skills-directory | Two values with the same `home` and different tokens. | Both `skillsDirectory` values are `<home>/.claude/skills`. |
| partner-paths-006 | equality | `PartnerPaths(home: /h, token: a)` against `PartnerPaths(home: /h, token: a)` and against `PartnerPaths(home: /h, token: b)`. | The first pair is equal; the second pair is not. |
| partner-paths-007 | no-file-access | `home` is a directory that does not exist; read every property. | Each returns a URL and nothing is created on disk. |
| partner-paths-008 | no-validation, skill-file | `home` `/h`; read `skillFile(jobID: "../x").path`. | `/h/.claude/skills/adkitchen-partner-../x/SKILL.md`, pinning the unvalidated result so a later decision to validate shows as a deliberate change. |

