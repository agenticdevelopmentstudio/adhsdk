import XCTest
@testable import AgenticDeveloperHubSDKSync

final class ADHSyncCatalogTests: XCTestCase {
    /// The two counts below are the point of this test: they fail loudly when the
    /// catalog changes, so a regeneration gets reviewed instead of landing silently.
    /// `gen_sync_catalog.py` lives in the adh repo and writes ONLY ADHSyncCatalog.swift
    /// \- it does not know this file exists, so whoever regenerates the catalog must
    /// update these by hand. They already drifted once (79/27 -> 97/44) across three
    /// regenerations before anyone noticed.
    func testCatalogShape() {
        XCTAssertEqual(ADHSyncCatalog.all.count, 102)
        XCTAssertEqual(ADHSyncCatalog.pullOnly.count, 50)
        // content.markdown_chunks (pull-only) took them from 100/49.
        XCTAssertTrue(ADHSyncCatalog.pullOnly.contains("content.markdown_chunks"))
        // pullOnly ⊆ all
        let names = Set(ADHSyncCatalog.all.map(\.resource))
        // platform.accounts (phase 3, pushable) took them from 101/50.
        XCTAssertTrue(names.contains("platform.accounts"))
        XCTAssertTrue(ADHSyncCatalog.pullOnly.isSubset(of: names))
        // no duplicates
        XCTAssertEqual(names.count, ADHSyncCatalog.all.count)
        // spot checks: the enrollment branch's 10 tables are present
        for resource in ["content.feed", "content.poll_votes", "content.reactions",
                         "content.papers", "notification.notifications", "social.follows",
                         "social.user_blocks", "project.participants",
                         "discussion.community_members", "persona_memory.links"] {
            XCTAssertTrue(names.contains(resource), resource)
        }
        // push-mode spot checks
        XCTAssertTrue(ADHSyncCatalog.pullOnly.contains("social.follows"))
        XCTAssertFalse(ADHSyncCatalog.pullOnly.contains("content.contacts"))
        // all v2 today
        XCTAssertTrue(ADHSyncCatalog.all.allSatisfy { $0.schemaVersion == 2 })
    }
}
