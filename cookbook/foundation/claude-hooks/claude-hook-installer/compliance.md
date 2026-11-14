
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | failed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns is partial: one type also owns hook registration, status-line slot arbitration, two marker files, the cross-process settings lock with `modifySettings`, and deleting the retired capture script, so the lock layer and the slot logic could each become their own ingredient. File-side status-line handling lives in `ClaudeStatusLine`, quoting in `ShellQuoting`, atomic writes in `AtomicFile`, and this type decides what is registered and edits `settings.json`. unit-test-coverage passes: `HookInstallerTests`, `HookInstallerBundleCommandTests` and `ClaudeHookInstallerCoexistenceTests` cover install, uninstall, legacy forms, the lock, the status-line slot and the capture script. explicit-error-handling passes: install and uninstall log and convert errors to a result, the others throw typed `ClaudeHookInstallerError` values. secure-storage passes: a new `settings.json` is created at `0600`, an existing mode is kept and the file is written atomically. secure-log-output fails: the status-line command and the capture-script path are logged with `privacy: .public`, and an adopted command can embed a token. no-hardcoded-strings fails: the error descriptions are English literals with no localization table.

