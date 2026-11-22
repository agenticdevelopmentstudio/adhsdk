#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

enum ModelBodyRewriter {
    /// New body with `model` replaced, `max_tokens` clamped to `maxOutput` when it is
    /// smaller, and an enabled thinking budget clamped under `max_tokens`.
    /// nil on any failure: the caller keeps the original bytes. An enabled
    /// thinking budget under a `max_tokens` below 1 is such a failure: there
    /// is no budget to clamp to, and the arithmetic must never trap.
    static func rewrite(_ object: [String: Any], model: String, maxOutput: Int?) -> Data? {
        var copy = object
        copy["model"] = model
        if let maxOutput, let current = copy["max_tokens"] as? Int, current > maxOutput {
            copy["max_tokens"] = maxOutput
        }
        if var thinking = copy["thinking"] as? [String: Any], thinking["type"] as? String == "enabled",
           let budget = thinking["budget_tokens"] as? Int, let max = copy["max_tokens"] as? Int {
            let (ceiling, overflow) = max.subtractingReportingOverflow(1)
            if overflow || ceiling < 0 { return nil }
            if budget > ceiling {
                thinking["budget_tokens"] = ceiling
                copy["thinking"] = thinking
            }
        }
        guard JSONSerialization.isValidJSONObject(copy) else { return nil }
        return try? JSONSerialization.data(withJSONObject: copy)
    }
}
#endif
