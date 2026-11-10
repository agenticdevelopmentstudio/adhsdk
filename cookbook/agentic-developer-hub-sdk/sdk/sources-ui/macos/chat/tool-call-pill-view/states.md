
| State | Appearance change |
|-------|------------------|
| Running (result == nil) | Text and border colored `.info` |
| Success (result.ok == true) | Text and border colored `.success` |
| Failed (result.ok == false) | Text and border colored `.danger`; error message appended to name |
| Theme changed | All colors updated to match the new palette; the same view instance recolors in place (no rebuild) |

