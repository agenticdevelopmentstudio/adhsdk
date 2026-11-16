import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `ExecutableLocator` over a fake file system: `isExecutable` answers from a set
/// of paths, and each test records the paths it was asked about.
struct ExecutableLocatorTests {

    private final class Probe: @unchecked Sendable {
        private let lock = NSLock()
        private var asked: [String] = []
        let present: Set<String>

        init(present: Set<String>) { self.present = present }

        func check(_ path: String) -> Bool {
            lock.lock()
            asked.append(path)
            lock.unlock()
            return present.contains(path)
        }

        var paths: [String] {
            lock.lock()
            defer { lock.unlock() }
            return asked
        }
    }

    private func locator(path: String?, probe: Probe) -> ExecutableLocator {
        // The default extra directories: /opt/homebrew/bin, /usr/local/bin, /usr/bin, /bin.
        ExecutableLocator(environment: path.map { ["PATH": $0] } ?? [:], isExecutable: { probe.check($0) })
    }

    @Test func pathEntriesComeFirstInOrder() {
        let probe = Probe(present: ["/custom/one/gh", "/custom/two/gh", "/opt/homebrew/bin/gh"])
        let found = locator(path: "/custom/one:/custom/two", probe: probe).find("gh")
        #expect(found == URL(fileURLWithPath: "/custom/one/gh"))
        #expect(probe.paths == ["/custom/one/gh"])
    }

    @Test func laterPathEntryWinsOverExtraDirectories() {
        let probe = Probe(present: ["/custom/two/gh", "/opt/homebrew/bin/gh"])
        let found = locator(path: "/custom/one:/custom/two", probe: probe).find("gh")
        #expect(found == URL(fileURLWithPath: "/custom/two/gh"))
    }

    @Test func extraDirectoriesAreSearchedAfterPath() {
        let probe = Probe(present: ["/usr/local/bin/gh"])
        let found = locator(path: "/usr/bin:/bin", probe: probe).find("gh")
        #expect(found == URL(fileURLWithPath: "/usr/local/bin/gh"))
        #expect(probe.paths == ["/usr/bin/gh", "/bin/gh", "/opt/homebrew/bin/gh", "/usr/local/bin/gh"])
    }

    @Test func extraDirectoriesAloneWithoutPath() {
        let probe = Probe(present: ["/opt/homebrew/bin/gh"])
        #expect(locator(path: nil, probe: probe).find("gh") == URL(fileURLWithPath: "/opt/homebrew/bin/gh"))
    }

    @Test func repeatedDirectoriesAreSearchedOnce() {
        let probe = Probe(present: [])
        let subject = locator(path: "/usr/bin:/opt/homebrew/bin/::/usr/bin", probe: probe)
        #expect(subject.searchDirectories == ["/usr/bin", "/opt/homebrew/bin", "/usr/local/bin", "/bin"])
        _ = subject.find("gh")
        #expect(probe.paths == ["/usr/bin/gh", "/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/bin/gh"])
    }

    @Test func relativeEntriesAreDropped() {
        let probe = Probe(present: ["./gh", "bin/gh"])
        let subject = locator(path: ".:bin:/usr/bin", probe: probe)
        #expect(subject.searchDirectories == ["/usr/bin", "/opt/homebrew/bin", "/usr/local/bin", "/bin"])
        #expect(subject.find("gh") == nil)
    }

    @Test func nilWhenAbsent() {
        let probe = Probe(present: ["/usr/bin/git"])
        #expect(locator(path: "/usr/bin", probe: probe).find("gh") == nil)
    }

    @Test func nameWithSlashOrEmptyFindsNothing() {
        let probe = Probe(present: ["/usr/bin/gh"])
        let subject = locator(path: "/usr/bin", probe: probe)
        #expect(subject.find("") == nil)
        #expect(subject.find("bin/gh") == nil)
        #expect(probe.paths.isEmpty)
    }
}
