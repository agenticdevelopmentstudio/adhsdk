
- **codable-sendable**: All four types MUST conform to `Codable` and `Sendable`, and the two responses MUST also conform to `Equatable`; the requests are not `Equatable`.
- **oversight-request-fields**: `OversightPreferenceRequest` MUST carry the optional fields `enabled` (Bool), `contextThresholdPct` (Int), `llmEnabled` (Bool), `selectedConfigId` (String) and `model` (String), all variables, all defaulting to nil in its initializer.
- **oversight-response-fields**: `OversightPreferenceResponse` MUST carry the non-optional constants `enabled` (Bool), `contextThresholdPct` (Int), `llmEnabled` (Bool), `selectedConfigId` (String) and `model` (String), all supplied to its initializer.
- **summary-request-fields**: `SummaryPreferenceRequest` MUST carry the optional fields `enabled` (Bool), `selectedConfigId` (String), `prompt` (String), `maxWords`, `activityLines`, `detailChars`, `intervalMinutes`, `maxPerRun` and `timeoutSeconds` (all Int), all variables, all defaulting to nil in its initializer.
- **summary-response-fields**: `SummaryPreferenceResponse` MUST carry `enabled` (Bool, optional), `selectedConfigId` (String, optional), `prompt` (String) and the non-optional Ints `maxWords`, `activityLines`, `detailChars`, `intervalMinutes`, `maxPerRun` and `timeoutSeconds`, all constants.
- **omitted-means-unchanged**: A request field that is nil MUST be absent from the encoded body, and the daemon MUST read an absent field as "leave the stored value alone".
- **summary-ownership**: `SummaryPreferenceRequest.enabled` and `selectedConfigId` MUST be the summaries switch and provider choice, owned by the app that shows the AI Summaries pane (the Kitchen); the remaining fields are tuning knobs.
- **tuning-clamped-by-daemon**: The client MUST NOT clamp the tuning values; the daemon clamps them through `SummaryLimits`, and the reply carries the stored result.
- **older-daemon-tolerance**: `SummaryPreferenceResponse` MUST decode when `enabled` and `selected_config_id` are absent, leaving both nil, because older daemons (before the toolkit's shared daemon core) returned neither and a missing field must not make the whole reply undecodable.
- **other-fields-required**: `SummaryPreferenceResponse` and `OversightPreferenceResponse` MUST fail to decode when any non-optional field is absent.
- **response-equality**: The two responses MUST compare equal when every field is equal, so a caller can tell whether a pushed value came back unchanged.
- **wire-spelling**: The types MUST be encoded and decoded with `StenographerWire` coders; they declare no `CodingKeys`, and their property names have no acronym runs, so the snake_case conversion round-trips.
- **public-initializers**: Each type MUST expose a public memberwise initializer, because the synthesized one is not public.

