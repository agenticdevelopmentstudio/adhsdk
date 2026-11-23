import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PartnerBasePrompt")
struct PartnerBasePromptTests {

    private func job(_ name: String, enabled: Bool) -> PartnerJob {
        PartnerJob(id: "general", name: name, isEnabled: enabled, guidelines: "Be useful.", steps: [])
    }

    @Test func systemPromptHasHeadingForEnabledJobOnly() {
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [
            job("General coding partner", enabled: true),
            job("Sleeper", enabled: false)
        ])
        #expect(prompt.hasPrefix(PartnerBasePrompt.text))
        #expect(prompt.contains("## Job: General coding partner\n\nBe useful."))
        #expect(!prompt.contains("## Job: Sleeper"))
    }

    @Test func systemPromptListsEachEnabledJobsStepsUnderItsHeading() throws {
        var general = job("General coding partner", enabled: true)
        general.steps = [
            PartnerJobStep(name: "open session", environment: .claude, command: "claude {dir}",
                           condition: "the shell prompt is showing")
        ]
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [general])
        let heading = try #require(prompt.range(of: "## Job: General coding partner"))
        let section = String(prompt[heading.upperBound...])
        #expect(section.contains("1. open session (Claude Code prompt): `claude {dir}`"))
        #expect(section.contains("when the shell prompt is showing"))
    }

    @Test func onlyCodeReviewStepsSayTheyArriveFilledFromReviewStart() {
        let line = "arrive filled in from `partner_review_start`"
        var reviews = PartnerJobDefaults.codeReviews()
        reviews.isEnabled = true
        var general = PartnerJob(id: "general", name: "General", isEnabled: false, guidelines: "g", steps: [])
        general.isEnabled = true
        #expect(PartnerBasePrompt.systemPrompt(jobs: [reviews]).contains(line))
        #expect(!PartnerBasePrompt.systemPrompt(jobs: [general]).contains(line))
    }

    @Test func baseTextForbidsGitOutput() {
        #expect(PartnerBasePrompt.text.contains("Never pass `--output` to a git command"))
    }

    @Test func baseTextNamesEveryToolAndKeyPhrases() {
        let tools = [
            "partner_projects_list", "partner_session_open", "partner_session_list", "partner_session_screen",
            "partner_session_run", "partner_session_wait", "partner_session_interrupt", "partner_session_close",
            "partner_attention_create", "partner_attention_update", "partner_attention_list", "partner_notify",
            "partner_review_next", "partner_review_start", "partner_review_finish"
        ]
        for tool in tools { #expect(PartnerBasePrompt.text.contains(tool), "missing \(tool)") }
        for phrase in ["attention item", "tick", "went idle"] {
            #expect(PartnerBasePrompt.text.contains(phrase), "missing \(phrase)")
        }
    }

    @Test func baseTextCoversButtonMessagesAndItemReplies() {
        let text = PartnerBasePrompt.text
        #expect(text.contains("Resolved: <text>"))
        #expect(text.contains("Confirmed: <text>"))
        #expect(text.contains("carries an item id"))
        #expect(text.contains("close that item with `partner_attention_update`"))
    }

    @Test func skillDescriptionIsYAMLQuoted() {
        let markdown = PartnerBasePrompt.skillMarkdown(for: job("Say \"hi\": a\\b", enabled: true))
        #expect(markdown.contains("guidelines for its Say \\\"hi\\\": a\\\\b job. "))
    }

    @Test func skillMarkdownHasFrontmatter() {
        let markdown = PartnerBasePrompt.skillMarkdown(for: job("General coding partner", enabled: true))
        let head = "---\nname: adkitchen-partner-general\n"
            + "description: \"The Agentic Developer Kitchen Coding Partner's guidelines for its General coding "
            + "partner job. Only for the Coding Partner, which has the partner_* tools; not for ordinary "
            + "requests.\"\n---\n"
        #expect(markdown.hasPrefix(head))
        #expect(markdown.contains("Be useful."))
    }

    private func step(_ name: String, _ environment: PartnerJobStep.Environment, _ command: String,
                      _ condition: String = "") -> PartnerJobStep {
        PartnerJobStep(name: name, environment: environment, command: command, condition: condition)
    }

    @Test("partner-base-prompt-009: no jobs gives the base text")
    func noJobsGivesBaseText() {
        #expect(PartnerBasePrompt.systemPrompt(jobs: []) == PartnerBasePrompt.text)
    }

    @Test("partner-base-prompt-010: only a disabled job gives the base text")
    func onlyDisabledJobGivesBaseText() {
        #expect(PartnerBasePrompt.systemPrompt(jobs: [job("Sleeper", enabled: false)]) == PartnerBasePrompt.text)
    }

    @Test("partner-base-prompt-011: job sections keep the given order")
    func jobSectionsKeepOrder() throws {
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [job("A", enabled: true), job("B", enabled: true)])
        let first = try #require(prompt.range(of: "## Job: A"))
        let second = try #require(prompt.range(of: "## Job: B"))
        #expect(first.lowerBound < second.lowerBound)
    }

    @Test("partner-base-prompt-012: a job without steps has no steps heading")
    func noStepsMeansNoStepsHeading() {
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [job("General", enabled: true)])
        #expect(prompt.hasSuffix("## Job: General\n\nBe useful."))
        #expect(!prompt.contains("### Steps"))
    }

    @Test("partner-base-prompt-013: a whitespace-only condition adds nothing")
    func whitespaceConditionAddsNothing() {
        var general = job("General", enabled: true)
        general.steps = [step("go", .terminal, "ls", "  \n ")]
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [general])
        #expect(prompt.hasSuffix("1. go (terminal shell): `ls`"))
    }

    @Test("partner-base-prompt-014: steps keep their order and no newline ends the prompt")
    func stepsKeepOrderWithoutTrailingNewline() throws {
        var general = job("General", enabled: true)
        general.steps = [step("one", .terminal, "ls"), step("two", .claude, "hi")]
        let prompt = PartnerBasePrompt.systemPrompt(jobs: [general])
        let first = try #require(prompt.range(of: "1. one (terminal shell): `ls`\n"))
        let second = try #require(prompt.range(of: "2. two (Claude Code prompt): `hi`"))
        #expect(first.lowerBound < second.lowerBound)
        #expect(!prompt.hasSuffix("\n"))
    }

    @Test("partner-base-prompt-015: the skill markdown ignores isEnabled")
    func skillIgnoresEnabled() {
        #expect(PartnerBasePrompt.skillMarkdown(for: job("General", enabled: true))
                == PartnerBasePrompt.skillMarkdown(for: job("General", enabled: false)))
    }

    @Test("partner-base-prompt-016: the base sections appear in order")
    func baseSectionsInOrder() throws {
        let headings = ["The window", "What reaches you", "Tools", "Attention items", "Sessions",
                        "Running a job's steps", "Git"]
        let text = PartnerBasePrompt.text
        var searchFrom = text.startIndex
        for heading in headings {
            let found = try #require(text.range(of: "## \(heading)\n", range: searchFrom..<text.endIndex))
            searchFrom = found.upperBound
        }
    }

    @Test("partner-base-prompt-017: systemPrompt is pure")
    func systemPromptIsPure() {
        let jobs = [job("A", enabled: true), job("B", enabled: false)]
        #expect(PartnerBasePrompt.systemPrompt(jobs: jobs) == PartnerBasePrompt.systemPrompt(jobs: jobs))
    }

    @Test("partner-base-prompt-018: the base text is the exact text with one-line paragraphs")
    func baseTextIsExactWithOneLineParagraphs() {
        #expect(PartnerBasePrompt.text == Self.exactBaseText)
        let lines = PartnerBasePrompt.text.components(separatedBy: "\n")
        for (first, second) in zip(lines, lines.dropFirst()) where !first.isEmpty && !second.isEmpty {
            let bothItems = first.hasPrefix("- ") && second.hasPrefix("- ")
            let bothRows = first.hasPrefix("|") && second.hasPrefix("|")
            #expect(bothItems || bothRows, "paragraph broken across lines at: \(first)")
        }
    }

    @Test("partner-base-prompt-019: the exact steps section")
    func exactStepsSection() {
        let reviews = PartnerJob(
            id: PartnerJobDefaults.codeReviewsID, name: "Code reviews", isEnabled: true, guidelines: "G",
            steps: [step("open", .claude, "claude {dir}", "the shell is ready"),
                    step("review", .terminal, "git status")])
        let expected = PartnerBasePrompt.text + "\n\n## Job: Code reviews\n\nG\n\n### Steps\n\n"
            + "These steps arrive filled in from `partner_review_start`; run the filled copy it returns.\n\n"
            + "1. open (Claude Code prompt): `claude {dir}`, when the shell is ready\n"
            + "2. review (terminal shell): `git status`"
        #expect(PartnerBasePrompt.systemPrompt(jobs: [reviews]) == expected)
    }

    @Test("partner-base-prompt-020: the skill name uses the id unchecked")
    func skillNameUsesIdUnchecked() {
        let odd = PartnerJob(id: "a b", name: "Odd", isEnabled: true, guidelines: "g", steps: [])
        #expect(PartnerBasePrompt.skillMarkdown(for: odd).contains("name: adkitchen-partner-a b\n"))
    }

    private static let exactBaseText = """
        # Coding Partner

        You are the Agentic Developer Kitchen's Coding Partner: one long-lived Claude Code session that \
        stays running for the owner and does several jobs. Each job below has its own guidelines. You are \
        one session with one memory, so use it: carry what you learn from one job into the next.

        ## The window

        The owner sees you in the Coding Partner window. A shelf along the side holds the terminal tabs you \
        open. The transcript shows this conversation. The Needs-you pane lists your attention items. \
        Everything you want the owner to notice goes into an attention item; the transcript is not where the \
        owner looks for work waiting on them.

        ## What reaches you

        You run only when a message arrives. Messages come in these kinds:

        - An owner message: the owner typed to you. Answer it, and do what it asks.
        - A button message: the owner clicked a button on an attention item, and the app sent it in the \
        owner's voice. "Resolved: <text>" means the owner handled a blocked item or a question; close that \
        item with `partner_attention_update`. "Confirmed: <text>" means the owner acknowledged a \
        notification; close that item the same way.
        - An owner reply that carries an item id: the owner answered an item you raised (after Discuss). Act \
        on the answer, then close the item with `partner_attention_update`.
        - A tick: a job's timer fired. Do that job's work now, using its guidelines.
        - A session went idle: a terminal session you opened has produced no output for a while. Read its \
        screen and decide what it needs.
        - A session exited: a session you opened ended. Check how it ended and follow up.
        - A lifecycle notice: you started (possibly resumed, with sessions that are gone), guidelines \
        changed, the app is about to quit, or a turn timed out.

        Between messages you do nothing. Never loop, sleep or poll to wait for something; a later message \
        will wake you.

        ## Tools

        adhd serves these tools under the app's name: `partner_projects_list` arrives as \
        `kitchen_partner_projects_list`.

        | Tool | Does |
        |---|---|
        | `partner_projects_list` | Lists the Projects registry: id, name, path, remote, current branch. |
        | `partner_session_open` | Opens a terminal tab with a working directory, optional title and \
        optional first command; returns its session id. |
        | `partner_session_list` | Lists the sessions you opened: id, title, directory, state, last \
        activity. |
        | `partner_session_screen` | Reads the last N lines of a session's screen. |
        | `partner_session_run` | Types a command into a session and returns the output once it settles. |
        | `partner_session_wait` | Waits for a session's output to settle, for a bounded time. |
        | `partner_session_interrupt` | Sends Control-C and returns what printed. |
        | `partner_session_close` | Closes a session's tab and ends its shell. |
        | `partner_attention_create` | Creates an attention item: kind, text, optional reference. |
        | `partner_attention_update` | Changes an item's text or marks it done. |
        | `partner_attention_list` | Lists open items, and done items still in the window. |
        | `partner_notify` | Posts a macOS notification and records it as an attention item of kind \
        notification. |
        | `partner_review_next` | Lists the queued code reviews, oldest first, and the running ones with \
        their sessions. |
        | `partner_review_start` | Starts one queued review and returns the job's steps with placeholders \
        filled. |
        | `partner_review_finish` | Marks a review done, failed or skipped with a summary. |

        ## Attention items

        When you need the owner, create an attention item with `partner_attention_create` and move on. Never \
        wait for an answer: the owner will reply when they see it, and that reply arrives as an owner \
        message. Use the kind that fits: a question you need answered, work that is blocked, or a \
        notification. When the thing an item asks for is resolved, mark it done with \
        `partner_attention_update`. Do not create duplicates of an attention item that is still open; update \
        it.

        ## Sessions

        Open a tab with `partner_session_open`. Type into it with `partner_session_run`. Read it with \
        `partner_session_screen`. Do not block on `partner_session_wait` for long work: start the work, end \
        your turn, and expect a message when the session went idle or exited. When one arrives, read the \
        screen before you decide anything. Close sessions you no longer need.

        ## Running a job's steps

        A job lists steps. Run them in order. Each step has an environment (a terminal shell or a Claude \
        Code prompt), a command, and a condition. Judge whether the condition holds from the session's \
        screen before you type the command; if it does not hold, wait for the next idle message or raise an \
        attention item. Never skip a step and never reorder them. Each job's steps are listed under its \
        heading below; a `{placeholder}` in a command is a value you fill in from the job's work.

        ## Git

        Use git only to read: log, show, diff and status. Never pass `--output` to a git command, because it \
        writes a file. Never change the owner's branches, commits or working trees yourself; the code-review \
        sessions you open do their work in their own worktrees.
        """
}
