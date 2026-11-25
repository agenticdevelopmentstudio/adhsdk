import Foundation

/// How a stored provider configuration (a template id, its plain field values,
/// its secrets and an optional model) becomes the `AIPluginConfig` bag a plugin
/// builds a request from. One place, so the daemon's one-shot completion and the
/// model registry resolve a configuration the same way.
extension AIPluginDescriptor {

    /// The template with `id`, or nil when the plugin no longer offers it.
    public func template(id: String) -> ProviderTemplate? {
        resolvedTemplates.first { $0.id == id }
    }

    /// The secret fields a configuration of `templateId` declares: the template's
    /// own field list, else the descriptor's shared one when the template id no
    /// longer resolves. Scoped to the template because a keyless template (Ollama)
    /// drops the shared `apiKey`, and listing it would make `buildRequest` reject
    /// the provider for a blank key it never needed.
    public func secretFields(templateId: String) -> [Field] {
        (template(id: templateId).map { fields(for: $0) } ?? fields).filter(\.isSecret)
    }

    /// The model a request uses: `stored` when it names one, else the template's
    /// default, else the descriptor's.
    public func effectiveModel(stored: String?, templateId: String) -> String {
        if let stored, !stored.isEmpty { return stored }
        if let template = template(id: templateId), !template.resolvedDefaultModel.isEmpty {
            return template.resolvedDefaultModel
        }
        return resolvedDefaultModel
    }

    /// The value bag for a request: `fields` as stored (a caller that wants the
    /// template's `defaultValues` under them merges those in first), then every
    /// declared secret (present even when empty, so `buildRequest` can
    /// tell "this template needs a key and it is blank" from "keyless"), then
    /// `model` last, because `model` is the key `AIPluginConfig` reserves for it.
    public func requestValues(
        templateId: String, fields: [String: String], secrets: [String: String], model: String
    ) -> [String: String] {
        var values = fields
        for field in secretFields(templateId: templateId) {
            values[field.key] = secrets[field.key] ?? ""
        }
        values["model"] = model
        return values
    }

    /// Whether `model` takes tool definitions natively: the template's model
    /// details say so. A model the template does not describe answers false, and
    /// the host then prompts for tool calls instead (`PromptedToolCallingPlugin`).
    public func declaresNativeTools(model: String, templateId: String) -> Bool {
        template(id: templateId)?.modelDetail(for: model)?.tools == true
    }
}
