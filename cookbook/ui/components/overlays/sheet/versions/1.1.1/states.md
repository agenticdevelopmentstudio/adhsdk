
| State | Appearance change |
|-------|------------------|
| Closed | Drawer is off-screen; overlay is not rendered. |
| Opening | Drawer animates into viewport; overlay fades in. Opacity and transform transition based on `--apt-anim-scale`. |
| Open | Drawer is fully visible at its final position; overlay covers background at full opacity. |
| Closing | Drawer animates out of viewport; overlay fades out. Uses `data-ending-style` for exit transition. |

