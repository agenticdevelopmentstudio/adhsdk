
The model registry is the suite's shared list of model configurations. Every
app and daemon on the Mac opens the same SQLite file; each entry (`ModelEntry`)
names a provider configuration (a plugin and one of its templates), its
non-secret field values, a default model, and the free-form roles it can fill
(`fast`, `smart`, `local`, `cheap`). Secret values (API keys and the like)
never enter the file: they live in a `ModelSecretStore` (the shared Keychain
group in production), and the entry stores only the names of its secret fields.
After every write the registry posts a cross-process change signal (a Darwin
notification in production) so every process holding the registry re-reads.

A consumer names the model it wants with a `ModelSelector`: a role, resolved
to the first enabled entry holding it, or a specific entry id with an optional
model override. Resolution yields a `ResolvedModel` (entry, model, secrets)
that `ResolvedModel.request(descriptor:)` turns into the model id and value bag
a plugin builds a request from. The registry also lists installed plugins
(`PluginSummary`, read from descriptors, no plugin code loaded), lists the
models an entry's provider offers, and runs a one-line round trip to an
entry's model (`ModelTestResult`).

It is a **logic** component with no visual surface. It is related to the
[adhsdk.ingredient.ai.models.model-catalog](cookbook:c8438764-89c9-4286-9b58-10c9cd175a97) only in that
both describe models for provider templates; the registry stores user
configurations and the catalog stores shared facts about model ids.

