
`InboundEvent.messageFailed(reason:)`
and `.transportError(message:)` carry only the hardcoded English strings
produced by `PersonaChatError.description` and the `fallback` arguments to
`describe(error:fallback:)`: `"PersonaChatCoordinator has been destroyed."`,
`"PersonaChatCoordinator does not support attachments."`,
`"PersonaChatCoordinator does not support widgets."`,
`"Couldn't start the conversation (\(status))."`,
`"Couldn't start the conversation."`, `"The chat request failed."`,
`"The chat stream failed."`, and `"Chat failed."`. None of these is backed
by `NSLocalizedString`, a string catalog, or any other lookup mechanism, and
no error code travels alongside `reason`/`message`, so localizing these messages is the host's job: it switches on the thrown
`PersonaChatError` case, not on the English text. A port keeps the same
strings as its fallback text.

