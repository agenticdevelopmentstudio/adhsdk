
The `label` prop's default value, `"Conversation transcript"`, is a user-facing string hardcoded in source (`Transcript.tsx`). It is only correct for the `en` locale; a host application MUST supply a localized `label` for other locales rather than relying on the default. The `thinkingLabels` prop is supplied by the parent application and is assumed to already be localized when passed through. Transcript performs no locale-aware formatting itself (no dates, numbers, currencies, or plurals).

