
- **Data collected**: The user's privacy words (alias and real pairs), held in memory as a `TextSubstitutionFilter`.
- **Storage**: In memory only for the vault's lifetime; the persistent copy is the device-only keychain item owned by `PrivacyWordStore`.
- **Transmission**: The words never leave the process except into the keychain. The distributed notification between apps on the Mac names the store and carries the process identifier only; it carries no words (MUST).
- **Retention**: Until the vault is deallocated; the keychain item persists until saved empty.
- **Authentication**: Every `authenticate` call proves the owner anew, so no success is cached; this is what stands between the words and someone else at the keyboard.
- **Violation handling**: A failed or cancelled authentication throws and changes nothing; a failed reload is dropped silently (see the open question on `reload-failure-ignored`).

