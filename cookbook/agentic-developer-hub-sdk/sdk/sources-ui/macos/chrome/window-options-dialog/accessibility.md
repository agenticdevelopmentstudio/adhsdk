
- **Dialog Window**:
  - Role: Modal dialog (AppKit window delegate handles modal session)
  - Label: Window title (provided by host)
  - Keyboard: ⌘W closes the dialog (see **dialog-window-keyboard-dismissal**); Tab navigates between controls; Enter/Space activate buttons

- **Gear Button**:
  - Role: Button
  - Label: The `gearshape` image's `accessibilityDescription`, set to the tooltip text at construction (see **gear-button-accessible-label**)
  - Action: Tap/click opens or closes the dialog

- **Slider** (`WindowOptionsSlider`):
  - Role: Slider
  - Labels: Title label above describes the setting; caption label (right-aligned) shows the current value for sighted users
  - Keyboard: Left/Right arrow keys adjust value continuously
  - Announce: The slider itself is a standard `NSSlider`, so VoiceOver announces its value as arrow keys adjust it. The caption label mirrors the same value in a sighted-user-facing string but is a plain text field, not a live accessibility announcement region — changing its text does not itself trigger a VoiceOver announcement.

- **Toggle** (`WindowOptionsToggle`):
  - Role: Checkbox
  - Label: Checkbox title text
  - Keyboard: Space toggles state
  - State announcement: Checkbox state (on/off) announced by screen reader; custom accessibility ID can be set

- **Reset Button** (`WindowOptionsResetButton`):
  - Role: Button
  - Label: "Reset to Defaults"
  - Keyboard: Space or Enter activates
  - Action: Tapping resets all window options to defaults

- **Target size**: macOS does not define a touch-target minimum the way iOS's 44×44pt does — these are pointer-driven click targets, not touch targets. The gear button's `gearshape` glyph is roughly 16×16pt but sits inside a 28pt-tall title bar accessory row, giving it a larger effective click area. The checkbox, slider knob, and reset button use standard AppKit control sizes (roughly 16–20pt content), which is platform-normal for these controls but does not meet a 44×44pt figure. See Compliance: `touch-target-size` (`partial`).

- **Accessibility Prefix**: Dialog rows use the prefix `"window.options"` for accessibility identifiers, ensuring unique and meaningful IDs when there are multiple window option dialogs.

