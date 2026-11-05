import Foundation

public enum AttachmentSource: Sendable {
    case remote(URL)
    case inline(Data)
}
