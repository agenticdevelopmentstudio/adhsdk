
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `onPointerDown` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerdown` fires; composed with, never replacing, the component's own `pointerdown` tracking. |
| `onPointerUp` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerup` fires; composed with, never replacing, the component's own `pointerup` tracking. |
| `onPointerLeave` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerleave` fires; composed with, never replacing, the component's own `pointerleave` tracking. |
| `onPointerEnter` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointerenter` fires; composed with, never replacing, the component's own `pointerenter` tracking. |
| `onPointerCancel` | `(event: React.PointerEvent) => void` (optional) | `undefined` | Consumer handler invoked when `pointercancel` fires; composed with, never replacing, the component's own `pointercancel` tracking. |
| `...props` | `ButtonPrimitive.Props` | — | All other Base UI `Button` props, forwarded unchanged. |

The handler event type is React's synthetic `React.PointerEvent` (the type `ButtonPrimitive.Props` declares), not the DOM `PointerEvent`.
