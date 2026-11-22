import Foundation

/// The session daemon's wire types: what a session daemon's routes return and
/// its clients decode. They were `StenographerXPCProtocol`'s DTOs, and keep
/// their names and fields inside this namespace, so a payload encoded by the
/// old daemon decodes here unchanged.
public enum Sessions {}
