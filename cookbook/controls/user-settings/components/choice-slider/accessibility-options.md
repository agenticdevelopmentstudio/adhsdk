
The component responds to accessibility display options through browser defaults and CSS framework styling:

- **Reduce Motion**: The browser's range input may use default animations for thumb movement. The source component adds no custom animation; browser and CSS framework Reduce Motion handling applies to the range input and caption.
- **Increase Contrast**: The browser's range input appearance and the CSS framework (via `aws-slider__input` and `aws-slider__caption` classes) respond to platform contrast settings. The component does not apply specific contrast overrides beyond framework defaults.
- **Differentiate Without Color**: Selection is conveyed via the slider thumb position and the visible caption label text, not color alone. The caption provides text-based indication independent of visual position.

