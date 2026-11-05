import AppKit

/// A decorative view that runs a loop while it is on screen and can be told to
/// stop.
///
/// The contract is one thing: an animation nobody can see costs nothing. A
/// switch that only hid the view would leave its timer running behind a hidden
/// layer, which is the whole reason the switch exists. Both calls must be
/// idempotent — a host may stop an already-stopped backdrop on the way to
/// being torn down.
@MainActor
public protocol AnimatedBackdrop: AnyObject {
    func startAnimating()
    func stopAnimating()
}
