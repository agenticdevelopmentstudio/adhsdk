
| State | Appearance change |
|-------|------------------|
| Default | Standard background, border color is `chatInputBorder`, text color is `userText`, placeholder is visible if input is empty |
| Focused | Border color changes to `chatInputFocus`, caret visible (platform-specific: bar on web/iOS/UIKit, block on macOS, system bar on Android) |
| Disabled | Input field is not editable, send button is disabled, visual indication of disabled state (opacity or color dimming per platform) |
| With Text | Send button is enabled |
| Empty/No Text | Send button is disabled, placeholder text visible |
| Block Caret (macOS only) | Character-cell block cursor instead of blinking bar; block can be solid or blinking (configurable per terminal theme) |

