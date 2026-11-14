
| State | Appearance change |
|-------|------------------|
| No claimant, in a provider | API slot shows the disabled API button; help slot shows `fallbackHelp` or the disabled help button |
| API claimed | API slot shows the claimant's control; the disabled API button is gone |
| Help claimed | Help slot shows the claimant's control; `fallbackHelp` and the disabled help button are gone |
| Two claimants of a kind | The later one holds the slot; the earlier one renders nothing |
| Claimant unmounts | The slot returns to the previous claimant of that kind, or to the fallback when there is none |
| Outside a provider | Row draws a disabled API button and a disabled help button, with no slot boxes |
| Actions present | The actions box appears immediately before the API slot |
| Hover | Not applicable for the row; the disabled buttons have no hover change |
| Focused (keyboard) | Not applicable for the disabled buttons, which are not focusable; claimed controls bring their own focus style |
| Pressed (active) | Not applicable: the block defines no `:active` style |
| Loading | Not applicable: the block has no loading state |

