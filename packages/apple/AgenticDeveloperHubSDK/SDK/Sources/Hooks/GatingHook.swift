import Foundation

public protocol GatingHook: Sendable {
    var points: Set<GatingPoint> { get }
    func gate(point: GatingPoint, context: any HookContext) async -> HookDecision
}
