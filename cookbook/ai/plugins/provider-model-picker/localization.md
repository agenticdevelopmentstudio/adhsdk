
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `providerModelPicker.providerLabel` | `Provider` | The provider row's default label |
| `aiModelPicker.label` | `AI Model` | The model row's default label |
| `aiModelPicker.chooseModel` | `Choose a Model` | The model row with no model, or with a leading choice selected |

The leading choices' titles are the caller's. The keys are the recipe's;
the source still uses the English literals, so `no-hardcoded-strings` fails
until it looks them up.

