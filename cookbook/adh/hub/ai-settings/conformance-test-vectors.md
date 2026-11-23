
The first eight vectors come from the named tests in `ServicesSection.test.tsx` beside the source, and
the ninth from the setup every one of them shares. The others are derived from the source's own
functions and from the phase 8 design. A vector marked "owed: ModelsTable.test.tsx (phase 8 Task 10)"
has no test yet; that file is not written.

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
| ai-settings-016 | available-checkbox | A model `{ id: "m1", available: true }`; one with `available: false`; one with no `available` (owed: ModelsTable.test.tsx (phase 8 Task 10)) | Ticked; unticked; ticked. |
| ai-settings-017 | available-change, set-availability-call | Untick the box of model `m1` on service `svc_1` (owed: ModelsTable.test.tsx (phase 8 Task 10)) | `setModelAvailability("svc_1", "m1", false)` is called and the services cache is revalidated. |
| ai-settings-018 | no-longer-offered, disabled-names-appended | A model with `offered: false` and `available: false` (owed: ModelsTable.test.tsx (phase 8 Task 10)) | The row shows "No longer offered" and an unticked checkbox. |
| ai-settings-019 | table-empty | A service with an empty model list | the text "No models yet — Connect or Refresh." and no table. |
| ai-settings-020 | cache-key-kept | Import `PERSONA_SERVICES_CACHE_KEY` from this package | It is the string `"persona-services"`. |
| ai-settings-021 | ai-settings-section | Render `AiSettingsSection` | The rail heading reads "AI Settings". |
| ai-settings-022 | services-read-failure | The list call rejects | The failure is reported with feature `services`, step `list`, and the pane shows the error rather than "Loading…". |
| ai-settings-023 | template-failure-degrades | The template call rejects while the create modal is open | The failure is reported (step `templates`), the template group is absent and the fields work by hand. |
| ai-settings-025 | delete-confirmation | Press Delete and decline the confirmation | No delete call is made. |
| ai-settings-026 | available-change-failure | Untick the box of a ticked model `m1` on service `svc_1` while `setModelAvailability` rejects with "boom" (owed: ModelsTable.test.tsx (phase 8 Task 10)) | The failure is reported with feature `services`, step `setModelAvailability`; an error line reads "boom"; the box is ticked again. |
| ai-settings-027 | re-enable-no-longer-offered | Tick the box of model `m9` with `offered: false` and `available: false` on service `svc_1`; the revalidated list no longer carries `m9` (owed: ModelsTable.test.tsx (phase 8 Task 10)) | The box was enabled; `setModelAvailability("svc_1", "m9", true)` is called; after revalidation no `m9` row is shown. |

