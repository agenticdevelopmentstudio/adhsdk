
Not applicable as a data handler: the module stores whatever the loaders return, in memory only, and sends nothing. Loader error messages reach clients in the `error` field and the server log; the module does not filter them, so a loader that puts a credential in an error message would expose it. The loaders own what their messages contain.

