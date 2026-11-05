import Foundation

public protocol InteractiveWidget: InlineDocument {
    var hasResponse: Bool { get }
}
