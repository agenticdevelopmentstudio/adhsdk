
The first eight vectors come from the named tests in `ServicesSection.test.tsx` beside the source, and
the ninth from the setup every one of them shares. Vectors 016, 017, 018, 026, 027, 028, 029 and 031 come
from the named tests in `ModelsTable.test.tsx` beside it, which renders the real `ServicesSection` and
mocks only the personas data client. The others are derived from the source's own functions and from
the phase 8 design.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-settings-001 | save-gate | An open service, unmodified (test "starts disabled for an unmodified service and enables after one field edit") | Save is disabled; after typing one character into Name it is enabled. |
| ai-settings-002 | save-recovery, save-payload | Rename the service to "Renamed" and press Save (test "re-disables Save after a successful save") | The patch call receives the id `svc_1` and exactly name "Renamed" and the unchanged base URL; afterwards a button named Save exists and is disabled. |
| ai-settings-003 | save-blocked-reason | Set Name to two spaces (test "says WHY Save is blocked when a required field is cleared") | Save is disabled and the text "A name is required." is shown; before the edit it was not shown. |
| ai-settings-004 | save-blocked-reason | A service that arrives with a blank name, untouched (test "stays silent about an already-blank name the user hasn't touched") | Save is disabled and "A name is required." is not shown. |
| ai-settings-005 | dirty-exit-guard | An unmodified service under a rail host (test "registers nothing while the open service is unmodified") | No exit guard is registered. |
| ai-settings-006 | dirty-exit-guard | Type "!" into Name under a rail host (test "publishes a guard reporting dirty once the draft is edited") | One guard is registered and it reports dirty. |
| ai-settings-007 | dirty-exit-guard | Type "!" then a backspace (test "withdraws the guard when the edit is reverted") | The guard is registered after the first key and withdrawn after the second. |
| ai-settings-008 | dirty-exit-guard, save-recovery | Edit the name and Save successfully (test "withdraws the guard after a successful save") | The guard is withdrawn once the patch call resolves. |
| ai-settings-009 | url-or-internal-selection, editor-keyed-by-service | Render with `urlSelection` naming service `svc_1` and a list holding it (the setup of every test in the file) | The editor for that service opens with its Save button visible. |
| ai-settings-010 | blank-draft-validation | Press Save in the create modal with a provider chosen and the name blank, then with a name only, then with a name and provider | "A name is required.", then "Select a provider.", then "A base URL is required."; with every field empty Save is disabled. |
| ai-settings-011 | unfilled-url-vars | Template base URL `https://{region}.example.com` with the region left blank | Create is refused with "Fill in all the URL fields."; with region "eu" the Base URL reads `https://eu.example.com`. |
| ai-settings-012 | template-label | Template "Fal" with modalities `["image"]`; template "OpenAI" with modalities null; template "X" with `["chat","audio"]` | "Fal (image)"; "OpenAI"; "X (audio)". |
| ai-settings-013 | number-format | Context 1,500,000; 128,000; 900; absent | "1.5M"; "128K"; "900"; an em dash ("—"). |
| ai-settings-014 | price-format, dash-for-missing | Input price 3, output price absent | "$3.00" and an em dash ("—"). |
| ai-settings-015 | capability-chips | A model supporting tools and thinking only; a model supporting none | Chips "tools" and "thinking"; a lone em dash ("—"). |
| ai-settings-016 | available-checkbox | A model `{ id: "m1", available: true }`; one with `available: false`; one with no `available` (test "ticks the box exactly when the model is available, and reads a missing value as available") | Ticked; unticked; ticked. |
| ai-settings-017 | available-change, set-availability-call | Untick the box of model `m1` on service `svc_1` (test "unticking calls setModelAvailability and revalidates the services cache") | `setModelAvailability("svc_1", "m1", false)` is called; the services cache is revalidated, with a matcher that accepts `PERSONA_SERVICES_CACHE_KEY` and rejects `"personas"`; the box then reads unticked. |
| ai-settings-018 | no-longer-offered, disabled-names-appended | A model with `offered: false` and `available: false`, after a listed model (test "shows a no-longer-offered model with the text and an unticked box") | The row shows "No longer offered" once and an unticked checkbox, after the listed model's row. |
| ai-settings-019 | table-empty | A service with an empty model list | the text "No models yet — Connect or Refresh." and no table. |
| ai-settings-020 | cache-key-kept | Import `PERSONA_SERVICES_CACHE_KEY` from this package | It is the string `"persona-services"`. |
| ai-settings-021 | ai-settings-section | Render `AiSettingsSection` | The rail heading reads "AI Settings". |
| ai-settings-022 | services-read-failure | The list call rejects | The failure is reported with feature `services`, step `list`, and the pane shows the error rather than "Loading…". |
| ai-settings-023 | template-failure-degrades | The template call rejects while the create modal is open | The failure is reported (step `templates`), the template group is absent and the fields work by hand. |
| ai-settings-025 | delete-confirmation | Press Delete and decline the confirmation | No delete call is made. |
| ai-settings-026 | available-change-failure | Untick the box of a ticked model `m1` on service `svc_1` while `setModelAvailability` rejects with "boom" (test "a failed change is reported, shows the message, and leaves the box at its last known state") | The failure is reported with feature `services`, step `setModelAvailability`; an error line reads "boom"; the box is ticked again. |
| ai-settings-027 | re-enable-no-longer-offered | Tick the box of model `m9` with `offered: false` and `available: false` on service `svc_1`; the revalidated list no longer carries `m9` (test "re-enabling a no-longer-offered model calls through, and the re-read list drops its row") | The box was enabled; `setModelAvailability("svc_1", "m9", true)` is called; after revalidation no `m9` row is shown. |
| ai-settings-028 | table-columns | A service with one model (test "puts Available last, after Caps") | The last two column headers read "Caps" and "Available". |
| ai-settings-029 | available-checkbox | A model with id `m1` and display name "Model One" (test "names each box after the model's display name") | A checkbox named "Available: Model One" exists. |
| ai-settings-030 | available-change-pending | Two models; untick the first while its call is unresolved | The first model's checkbox is disabled and the second's is enabled; once the call settles the first is enabled again. |
| ai-settings-031 | available-change-pending, available-change-failure | Untick `m1`, then `m2`, on service `svc_1` while both calls are unresolved; `m1`'s call resolves, then `m2`'s rejects with "m2 failed" (test "two overlapping changes on different models each keep their own box disabled until their own request settles") | Both boxes are disabled; after `m1` answers only `m1`'s box is enabled; after `m2` fails its box is enabled and ticked, an error line reads "m2 failed", and the failure is reported with step `setModelAvailability`. |

