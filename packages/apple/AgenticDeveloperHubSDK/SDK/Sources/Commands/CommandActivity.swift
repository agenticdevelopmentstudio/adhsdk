import Foundation

/// One command's life: the invocation, and its result once one arrives.
/// `result == nil` is the running state a pill renders in `.info`.
///
/// A **struct**, deliberately, though every sibling property on
/// `ChatViewModel` is `[any Protocol]`. Those are extension points a host
/// substitutes its own types into; this one is a pairing of two protocols the
/// host already supplies, with nothing left to vary. A `CommandActivity`
/// protocol would add an extension point nobody can use.
public struct CommandActivity: Sendable, Identifiable {

    public let invocation: any CommandInvocation

    /// `nil` until the matching `commandCompleted` arrives. `ObservableChat
    /// ViewModel` fills it in place, matching `result.invocationID` against
    /// `invocation.id`; a result whose invocation was never seen is dropped
    /// rather than synthesised into an activity with no invocation to name.
    public let result: (any CommandResult)?

    /// The invocation's id, which is per-invocation and stable across
    /// completion — so a view can find the row it already drew rather than
    /// appending a second one when the result lands.
    public var id: String { invocation.id }

    public var isRunning: Bool { result == nil }

    public init(invocation: any CommandInvocation, result: (any CommandResult)? = nil) {
        self.invocation = invocation
        self.result = result
    }
}
