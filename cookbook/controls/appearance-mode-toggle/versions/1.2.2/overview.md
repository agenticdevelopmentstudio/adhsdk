
The Appearance Mode Toggle is a button component that allows users to cycle through three appearance modes: auto, light, and dark. The component reads the current appearance mode from the document element's `data-appearance-mode` attribute and the resolved appearance (whether dark mode is active) from the document element's class list. It displays an icon indicating the current resolved appearance (sun for light, moon for dark) and an optional badge indicator when in auto mode. Clicking the button dispatches a custom event to cycle to the next appearance mode.

