
| State | Appearance change |
|-------|------------------|
| Default | All unselected choices render with empty indicator |
| Selected | Selected choice renders with filled/checked indicator and checked input attribute |
| Disabled (group) | The fieldset receives the disabled attribute and every radio input inside it matches `:disabled`; text may render grayed out per CSS |
| Disabled (individual choice) | Individual radio input receives disabled attribute; that choice's option appears inactive |
| Focused | No focus style is defined for the `aws-radio` classes; because the native input is visually hidden, any focus indication must come from the caller's stylesheet |

