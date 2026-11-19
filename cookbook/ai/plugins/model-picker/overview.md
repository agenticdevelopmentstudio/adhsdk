
The model picker is how a person chooses one provider configuration's model
anywhere the Kitchen or Stenographer configures AI: the AI Providers panel's
default model, the Coding Partner, AI Summaries, AI Oversight, the Sessions
window and the AI chat window. It is one component in two parts:

- **The model chooser**: a filterable list of the provider's models beside a
  detail pane describing the selected one (capabilities, specs, provider
  terms, memory fit, popularity, rank, description), shown in a transient
  popover. It is presented only through one entry point, which takes the view
  to point at, a chooser context (the provider's plugin, template, base URL,
  key, current model and memory-guard thresholds) and a choice callback.
- **The model picker control**: a settings row reading
  `<label> ⌄ : <model name>`. Clicking its caret or its name opens the
  chooser, anchored to the caret. It is the chooser's only anchor in settings.

The control knows nothing about storage. Its caller supplies, through
injected closures, the name to show, the context to list and what to do with
a choice. The combined provider-and-model control
([adhsdk.ingredient.ai.plugins.provider-model-picker](cookbook:c9385bf6-3abc-486b-82b5-d57a62d86735)) is the
usual caller; the AI Providers panel's default model row
([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)) is another.

What the list holds and how it filters (the use facets, the fits-this-Mac
filter, the all-versions toggle, the scattered-letter search) is the model
catalog's and the facets' business
([adhsdk.ingredient.ai.models.model-catalog](cookbook:c8438764-89c9-4286-9b58-10c9cd175a97),
[adhsdk.ingredient.ai.models.model-use-facet](cookbook:f628f7f9-9c7b-4820-a4bf-231312a74839)); the
large-model tiers are the fit policy's
([adhsdk.ingredient.ai.models.local.model-fit-policy](cookbook:5069f11f-e0c6-40c3-92ca-6152b8df3bc2)). This
recipe covers the presentation, the choosing rules and the control.

