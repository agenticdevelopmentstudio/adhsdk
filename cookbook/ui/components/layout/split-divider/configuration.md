| Prop | Type | Required | Default | Description |
|---|---|---|---|---|
| `ratio` | `number` | yes | — | Current leading-pane ratio (0–1). |
| `onRatioChange` | `(ratio: number) => void` | yes | — | Called with the new ratio, already clamped to `[minRatio, maxRatio]`. |
| `containerRef` | `React.RefObject<HTMLElement \| null>` | yes | — | The split container that pointer drags are measured against. |
| `minRatio` | `number` | no | `0.2` | Lower clamp bound. |
| `maxRatio` | `number` | no | `0.8` | Upper clamp bound. |
| `step` | `number` | no | `0.03` | Ratio change per arrow key or step-button press. |
| `orientation` | `"horizontal" \| "vertical"` | no | `"horizontal"` | The separator's own orientation, per `aria-orientation`. |
| `label` | `string` | no | `"Resize split"` | `aria-label` of the separator. |
| `growBottomLabel` | `string` | no | per orientation | `aria-label` of the shrink button (see **step-button-labels**). |
| `growTopLabel` | `string` | no | per orientation | `aria-label` of the grow button (see **step-button-labels**). |
| `className` | `string` | no | — | Extra classes on the root row/column. |

There are no configuration files, environment variables, or runtime settings.
