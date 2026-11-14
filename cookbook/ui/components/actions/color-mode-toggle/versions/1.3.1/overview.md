
The Color Mode Toggle is a button component that allows users to cycle between three color modes: **auto** (follow system preference), **dark**, and **light**. The component is presentation-only — it accepts the current mode as a prop and notifies the parent via a callback when the user requests a change. This design allows the component to be used in any context where color mode preference needs to be controlled, regardless of where that preference is stored (user account, localStorage, application state).

The component visually indicates the current mode with three icon states (Sun for light, Moon for dark, RefreshCw refresh icon for auto). When the mode is "auto", the component queries the system's `prefers-color-scheme` to determine and display the currently active effective mode.

Not to be confused with [adhsdk.ingredient.controls.appearance-mode-toggle](cookbook:46e077a8-1171-4564-9781-7997ff76813a), a separate ingredient with the same three-state cycling shape that binds a different, legacy document contract (`data-appearance-mode` plus an `awt:appearance-cycle` event) for one demo site. See Design Decisions for why the two stay separate.

