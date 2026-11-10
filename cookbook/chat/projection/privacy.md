
Not applicable: this module defines no credential, token, or account-identifying field. It serializes only caller-supplied display data (`content`, `popover`, `toolCalls`) into an `Attachment` byte payload and performs no storage or transmission of its own — those are the concerns of `ChatBackendAdapter` and whatever persistence layer sits behind it, not of this projection.

