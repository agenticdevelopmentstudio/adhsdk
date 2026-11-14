
Not applicable: the module passes a connection description, which may include an authentication token, to the worker thread in the same process, and stores or sends nothing else. Reasons surfaced to `onExit` carry thread error text, which the host decides how to log.

