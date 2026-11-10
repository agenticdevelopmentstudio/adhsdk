
No logging. `UserCard` is a pure presentational component. It emits no telemetry
or structured log events. Error logging (e.g. avatar load failures) is delegated
to the browser console and handled by Base UI's `Avatar.Image` built-in error
handling (it transitions to error and reveals `Avatar.Fallback`).

