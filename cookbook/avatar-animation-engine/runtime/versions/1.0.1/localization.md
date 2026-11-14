
Not applicable: the only strings this runtime handles are channel
identifiers (`"eye.scaleY"`, `"body.ink"`), opaque channel payload values
(hex colors, SVG path data), and ease names — none is user-facing display
text. The developer-facing error descriptions (`Ease.Failure.unknown`,
`Color.Failure.badHex`, `PathError`'s cases, the Swift `Codable` decode
error) are fixed English diagnostic strings, not localized or exposed to end
users by these files.

