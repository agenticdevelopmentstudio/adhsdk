
| State | Appearance change |
|-------|------------------|
| Empty | Before the first pull every read returns nothing. |
| Synced | Reads return the mirrored rows. |
| Signed out | `signOut` leaves the tables empty until the next identity's first pull. |

