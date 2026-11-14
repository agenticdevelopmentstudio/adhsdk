
The module does not log. Failures reach the host as a rejection (a failed start) or through `opts.onExit` (a later crash or exit). The slow-call warning is logged from the worker and belongs to Storage Worker ([adhsdk.ingredient.status.service.libsql.storage-worker](cookbook:020cc0f0-04e9-4d03-8796-76027fb1131f), `slow-call-warning`), not to this module.

