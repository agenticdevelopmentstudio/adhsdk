import Foundation

/// Which daemon feature asked for a completion — the `ai_interactions` log discriminator.
public enum AIFeature: String, Sendable {
    /// The Sessions feature's summaries (the original, hence the bare name).
    case summarize
    case oversight
    /// The AI Conversations feature's summaries.
    case summarizeConversations = "summarize_conversations"
    /// The Coding Projects feature's summaries.
    case summarizeProjects = "summarize_projects"
}
