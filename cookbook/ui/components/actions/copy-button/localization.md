
The success title `"Copied!"`, set on the `title` attribute in the `CopyButton`
component (`copy-button.tsx`), is a hard-coded, user-visible string — a hover
tooltip a user actually reads, not an internal technical value, so it is not exempt
from translation. The component exposes no way to localize or override it: a
consumer can localize the idle state via the `label` prop, but the success-state
title is fixed regardless of locale. This is a real gap for a fully localized
deployment (see Compliance); closing it would mean externalizing `"Copied!"` or
exposing it as an optional prop.

