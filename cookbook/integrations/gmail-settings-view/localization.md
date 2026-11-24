
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal) | OAuth Client | Section heading |
| (literal) | Current client ID / Current secret | Grid labels |
| (literal) | Client ID / Client secret | Field labels |
| (literal) | ….apps.googleusercontent.com | Client ID prompt |
| (literal) | Save Client / Replace Client | Save button |
| (literal) | Import Client JSON… / Replace from JSON… | Import button |
| (literal) | or | Between buttons |
| (literal) | Accounts signed in with a replaced client need Reconnect. | Hint caption |
| (literal) | Accounts | Section heading |
| (literal) | Add the OAuth client above before adding an account. | Hint caption |
| (literal) | Add Account… / Remove / Cancel / Reconnect / Sync Now / Show Error | Buttons |
| (literal) | Waiting for Google sign-in in your browser… | Sign-in progress |
| (literal) | Sync archived mail / Sync junk mail / Sync deleted mail | Toggles |
| (literal) | Fetch mail from the last / Check for mail every | Picker labels |
| (literal) | n days / n minutes | Picker choices |
| (literal) | Gmail / email couldn't sync / OK | Alert title and button |
| (literal) | Remove email? / This signs the account out of Google, removes its stored sign-in and deletes its mail from this Mac. / Remove | Removal confirmation |

The source has no string catalog or externalization step; strings are literals in the view and the model, and the relative-time text is the only part formatted for the current locale (a relative date formatter with the current locale). The picker labels "n days" and "n minutes" use no plural rules, so a stored value of 1 would read "1 days".

