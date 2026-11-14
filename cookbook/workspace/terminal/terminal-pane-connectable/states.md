
| State | Appearance change |
|-------|------------------|
| Offering a terminal | The connectable terminal property returns a session. |
| Not offering a terminal | The property returns nothing: no session, or the selected session has stopped. |
| Starting | The start has been called and has not returned; the property still returns nothing until a session runs. |
| Pressed / Disabled / Focused / Loading | Not applicable: a protocol has no appearance states; the starting state above is the only transient state. |

