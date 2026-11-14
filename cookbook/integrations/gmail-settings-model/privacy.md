
- **Data collected**: The model holds the user's Gmail account emails, sync status and last error messages, and the OAuth client id and secret the user types.
- **Storage**: The model keeps these in memory only. The service stores the OAuth client; only a short suffix of the secret returns to the model after import (see the mail integration service, [adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)), so the whole secret never does.
- **Transmission**: The drafts leave the process only in the import request to the injected client. Drafts clear after the service accepts them.
- **Retention**: The drafts stay in memory after a rejected import so the user can correct them; the model does not persist them.

