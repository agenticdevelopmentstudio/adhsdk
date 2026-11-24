
The module passes a connection description, which may include an authentication token (`authToken`), to the worker thread in the same process, and stores or sends nothing else. It never logs `workerData`, and the host MUST NOT log it either. Reasons surfaced to `onExit` carry thread error text, which may include driver text, so the host decides how to log them.

