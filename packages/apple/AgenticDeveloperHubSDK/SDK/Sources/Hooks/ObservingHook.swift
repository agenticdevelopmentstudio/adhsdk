import Foundation

public protocol ObservingHook: Sendable {
    var points: Set<ObservingPoint> { get }
    func observe(point: ObservingPoint, context: any HookContext) async
}
