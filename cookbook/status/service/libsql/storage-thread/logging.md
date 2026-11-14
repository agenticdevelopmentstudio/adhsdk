
The module does not log. Failures reach the host as a rejection (a failed start) or through `opts.onExit` (a later crash or exit). The database thread's server writes `[storage] slow call <path> <ms>ms` with `console.warn` for a call of 2000 ms or more; that is logged from the worker, not from this module.

