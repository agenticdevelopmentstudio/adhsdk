
- **table-identifier**: The table carries the identifier `accounts.detail`.
- **user-row-identifier**: The user row carries `accounts.detail.user`.
- **spinner-row-identifier**: The status row carries `accounts.detail.spinner`.
- **login-row-identifier**: The Login row carries `accounts.detail.login`.
- **signup-row-identifier**: The Signup row carries `accounts.detail.signup`.
- **logout-row-identifier**: The Logout row carries `accounts.detail.logout`.
- **traits-and-labels**: NEEDS REVIEW: Not implemented in source. Behavior undefined. The source sets no accessibility labels, traits or hints; action rows read as plain table cells and a disabled action is distinguished only by color and by being unhighlightable. A review of VoiceOver output for a disabled action row would settle whether a not-enabled trait is needed.
- **dynamic-type**: The screen MUST leave text sizing to the default list content configuration. It sets no font or text-style override, so the system text styles apply and scale with the user's text size setting.
- **differentiate-without-color**: NEEDS REVIEW: Not implemented in source. Behavior undefined. Disabled actions differ from enabled ones only by text color; evidence from an increase-contrast and color-differentiation review would settle whether a second cue is needed.
- Minimum tap target: the rows use the table's default row height; the source sets no explicit target size.

