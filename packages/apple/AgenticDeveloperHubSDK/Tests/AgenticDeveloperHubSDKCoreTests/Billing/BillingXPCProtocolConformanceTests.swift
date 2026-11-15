import XCTest
@testable import AgenticDeveloperHubSDKCore

/// `BillingXPCProtocol` is a pure wire declaration; every vector describes how
/// a daemon that implements it replies. No daemon lives in this package, and a
/// fake implementing the protocol would only assert its own code, so each
/// vector is skipped with that reason. The client's reading of these reply
/// conventions is covered by `BillingXPCClientTests`.
final class BillingXPCProtocolConformanceTests: XCTestCase {

    private func daemonOnly(_ behavior: String) throws {
        throw XCTSkip(
            "Daemon behavior (\(behavior)): the protocol is a declaration "
                + "and no implementing daemon is in this package.")
    }

    func testV1_emptyNameSaveRepliesNilThenTheSentence() throws { try daemonOnly("save reply shape") }
    func testV2_successfulSaveRepliesTheStoredClientThenNil() throws { try daemonOnly("save reply shape") }
    func testV3_failedClientsReadRepliesTheReadFailedRow() throws { try daemonOnly("list read failure") }
    func testV4_throwingAssignRepliesMinusOne() throws { try daemonOnly("count failure") }
    func testV5_assignWithNothingToMoveRepliesZero() throws { try daemonOnly("count failure") }
    func testV6_savingABilledEntryRepliesNilWithASentence() throws { try daemonOnly("entry writes") }
    func testV7_deletingALockedEntryRepliesFalseWithASentence() throws { try daemonOnly("entry writes") }
    func testV8_clientReadIncludesArchivedClients() throws { try daemonOnly("clients and projects") }
    func testV9_idleCutoffOf9999IsClampedTo480() throws { try daemonOnly("set preferences") }
    func testV10_failedPreferencesWriteRepliesEmptyData() throws { try daemonOnly("set preferences") }
    func testV11_startingATimerClosesTheRunningOne() throws { try daemonOnly("timers") }
}
