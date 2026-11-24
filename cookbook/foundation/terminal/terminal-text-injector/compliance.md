
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.platform-compliance.platform-permissions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90cb6a83-7544-53ea-8d2c-30851b253122) | passed | Platform Compliance |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | Performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns passes: the type resolves a pane, builds scripts and runs them, while the choice of what to type and when belongs to its callers (the session watcher and the app). unit-test-coverage is partial: `TerminalTextInjectorTests` (`Tests/AgenticDeveloperHubSDKCoreMacOSTests/TerminalTextInjectorTests.swift`) covers every vector except 032, 033 and 035, including `run` and the permission mapping through in-process AppleScript errors. Vectors 032, 033 and 035 are skipped because `inject` needs a live iTerm2 or Terminal.app pane to answer the scripts, and vector 031 covers only the `boom` message, since AppleScript always supplies one. explicit-error-handlingexplicit-error-handling passes: every failure is a typed `InjectionError` returned in a `Result`. input-sanitization passes: the text, uuid and TTY are escaped before interpolation and line breaks and control keys are removed. platform-permissions passes: an Automation denial is detected and returned with the terminal's bundle id for the app's permission UI. main-thread-freedom is partial: the wait is an `await` and the TTY lookup is a syscall, but `NSAppleScript` executes synchronously on the main actor. no-hardcoded-strings fails: the error texts are English literals with no localization lookup.

