
Not applicable: Component performs no logging.

<!-- appkit-avatar -->
AppKit `AvatarView` logs failed loads, non-2xx answers and undecodable bytes at debug level through its `Loggable` logger; the URL is never logged.

