
Not applicable: this source does not call any analytics or telemetry API. Neither `MobileChatViewController` nor `MobileChatView`/`MobileChat` contains an event-tracking call. A host that wants analytics for this surface would add its own instrumentation around `open(animated:)`/`close(animated:)`, `sendTapped()`/`submitMessage()`, and the close action.

