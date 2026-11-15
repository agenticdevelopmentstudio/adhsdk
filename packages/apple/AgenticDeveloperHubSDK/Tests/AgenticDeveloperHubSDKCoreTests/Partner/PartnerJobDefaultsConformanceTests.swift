import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner job defaults conformance") struct PartnerJobDefaultsConformanceTests {
    private static let expectedGuidelines = """
        On a tick, the message says how many reviews are queued and running. Call `partner_review_next`, then \
        start reviews with `partner_review_start`, oldest first, while `running` is below `concurrency`. Never \
        start two reviews in one repo. When a start says the repo's review worktree needs the owner, the review \
        stays queued and the owner has been told: start no other review of that repo and branch this tick.

        A `partner_review_start` result that is skipped (no session, no steps) needs nothing more: the app has \
        already marked it. Otherwise it names the review's session and lists its steps with their placeholders \
        filled. Run them in order in that session: a terminal step's command with `partner_session_run`, and a \
        claude step's prompt text with `partner_session_run` too, typed at Claude Code's prompt. Check each \
        step's condition on the screen before typing it. If the review step's `/code-review` rejects the bare \
        sha as its target, type it again with the range `{sha}^..{sha}` in the sha's place.

        On a session idle event for a review session, read its screen with `partner_session_screen` and decide: \
        the current step is still working (end your turn), it finished (type the next step), the last step \
        finished (call `partner_review_finish` with `done` and a one-paragraph summary of the findings fixed \
        and the findings skipped, and why), or it is stuck or waiting on something you cannot answer (raise an \
        attention item). Answer what Claude Code asks on the way, the trust-this-folder prompt included.

        On a session exited event for a review session that is not finished, call `partner_review_finish` with \
        `failed` and what the screen last showed.

        Never wait on `partner_session_wait` longer than its maximum; end your turn and let the idle event wake \
        you. Nothing is pushed: the fixes stay on the fix branch for the owner to merge.
        """

    private static let expectedFixCommand = "Fix every finding that still applies at the tip. Skip findings whose "
        + "code the later commits ({superseded}) already changed or removed, and say which. Commit on "
        + "{fix_branch} with the trailer \"Reviewed-Commit: {sha}\". Do not push: the fixes stay on "
        + "{fix_branch} for the owner to merge. Report what was fixed and what was skipped."

    private var job: PartnerJob { PartnerJobDefaults.codeReviews() }

    @Test("V1: the defaults hold the code reviews job and its three steps")
    func testV1_allContentsAndStepNames() {
        #expect(PartnerJobDefaults.all.map(\.id) == ["code-reviews"])
        #expect(job.steps.map(\.name) == ["open session", "review", "fix"])
    }

    @Test("V2: the fix step commits on the fix branch and never pushes")
    func testV2_fixStepCommitsAndNeverPushes() {
        let command = job.steps[2].command
        #expect(command.contains("Commit on {fix_branch}"))
        #expect(command.contains("Do not push"))
        #expect(command.contains("\"Reviewed-Commit: {sha}\""))
    }

    @Test("V3: the guidelines name the loop tools and the range fallback")
    func testV3_guidelinesNameTools() {
        let text = job.guidelines
        for needle in ["partner_review_next", "partner_review_start", "partner_review_finish",
                       "partner_session_run", "partner_session_wait", "{sha}^..{sha}"] {
            #expect(text.contains(needle), "missing \(needle)")
        }
    }

    @Test("V4: a fresh default carries the same steps and guidelines as the constants")
    func testV4_reproducible() {
        #expect(job.steps.count == 3)
        #expect(job.steps == PartnerJobDefaults.codeReviews().steps)
        #expect(job.guidelines == PartnerJobDefaults.codeReviewsGuidelines)
    }

    @Test("V5: the id constants")
    func testV5_idConstants() {
        #expect(PartnerJobDefaults.codeReviewsID == "code-reviews")
        #expect(PartnerJobDefaults.retiredGeneralID == "general")
    }

    @Test("V6: the retired general job is not a default")
    func testV6_noGeneralJob() {
        #expect(!PartnerJobDefaults.all.contains { $0.id == "general" })
    }

    @Test("V7: the job's identity and settings")
    func testV7_jobFields() {
        #expect(job.id == "code-reviews")
        #expect(job.name == "Code reviews")
        #expect(!job.isEnabled)
        #expect(job.scheduleSeconds == 1800)
        #expect(job.isBuiltIn)
    }

    @Test("V8: the open session step")
    func testV8_openSessionStep() {
        let step = job.steps[0]
        #expect(step.environment == .terminal)
        #expect(step.command == "claude --model {model} --dangerously-skip-permissions")
        #expect(step.condition == "A fresh tab in the review worktree.")
    }

    @Test("V9: the review step")
    func testV9_reviewStep() {
        let step = job.steps[1]
        #expect(step.environment == .claude)
        #expect(step.command == "/code-review high {sha}")
        #expect(step.condition == "Claude Code is at its prompt; no review already running in this repo.")
    }

    @Test("V10: the fix step's environment, condition and wording")
    func testV10_fixStep() {
        let step = job.steps[2]
        #expect(step.environment == .claude)
        #expect(step.condition == "The review has finished.")
        #expect(step.command.contains("{superseded}"))
        #expect(step.command.contains("Report what was fixed and what was skipped."))
    }

    @Test("V11: the commands use exactly four placeholders")
    func testV11_placeholders() throws {
        let pattern = try NSRegularExpression(pattern: "\\{([A-Za-z_]+)\\}")
        var found = Set<String>()
        for step in job.steps {
            let range = NSRange(step.command.startIndex..., in: step.command)
            for match in pattern.matches(in: step.command, range: range) {
                if let word = Range(match.range(at: 1), in: step.command) { found.insert(String(step.command[word])) }
            }
        }
        #expect(found == ["model", "sha", "fix_branch", "superseded"])
    }

    @Test("V12: the job's guidelines are the constant")
    func testV12_guidelinesConstant() {
        #expect(job.guidelines == PartnerJobDefaults.codeReviewsGuidelines)
    }

    @Test("V13: every call builds a fresh value")
    func testV13_freshValues() {
        var changed = PartnerJobDefaults.codeReviews()
        changed.isEnabled = true
        #expect(!PartnerJobDefaults.codeReviews().isEnabled)
        #expect(PartnerJobDefaults.codeReviews() == PartnerJobDefaults.codeReviews())
    }

    @Test("V14: the tick, one-per-repo and skipped-start guidance")
    func testV14_tickGuidance() {
        let text = job.guidelines
        #expect(text.contains("while `running` is below `concurrency`"))
        #expect(text.contains("Never start two reviews in one repo"))
        #expect(text.contains("skipped (no session, no steps)"))
    }

    @Test("V15: the idle, exit and no-push guidance")
    func testV15_eventGuidance() throws {
        let text = job.guidelines
        let finish = try #require(text.range(of: "partner_review_finish"))
        #expect(text[finish.upperBound...].contains("with `done`"))
        #expect(text.contains("On a session exited event for a review session that is not finished"))
        #expect(text.contains("Nothing is pushed"))
    }

    @Test("V16: the guidelines are the exact text")
    func testV16_guidelinesExact() {
        #expect(PartnerJobDefaults.codeReviewsGuidelines == Self.expectedGuidelines)
    }

    @Test("V17: the fix command is the exact text")
    func testV17_fixCommandExact() {
        #expect(job.steps[2].command == Self.expectedFixCommand)
    }
}
