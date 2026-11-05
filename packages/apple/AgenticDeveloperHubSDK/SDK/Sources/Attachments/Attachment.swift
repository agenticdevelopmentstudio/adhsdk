import Foundation

public protocol Attachment: Sendable {
    var id: String { get }
    var mediaType: any MediaType { get }
    var source: AttachmentSource { get }
    var presentation: AttachmentPresentation { get }
    var displayName: String? { get }
    var byteSize: Int? { get }
}
