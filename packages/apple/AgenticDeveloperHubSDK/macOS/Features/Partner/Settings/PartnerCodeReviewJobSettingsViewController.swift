import AppKit
import Combine

import AgenticDeveloperHubSDKCore
import os

/// Code Review: the one job the partner has. Its guidelines and steps, how the crawl and the reviews
/// run, and which projects are reviewed.
@MainActor
// swiftlint:disable:next type_name
public final class PartnerCodeReviewJobSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private static let logger = Logger(subsystem: "com.mikefullerton.agenticdeveloperhubsdk",
                                       category: "PartnerCodeReviewJobSettings")
    /// The per-repo `review_setting` key the Review column writes; "1" means the repo is not reviewed.
    static let optedOutKey = "opted_out"
    private static let jobID = PartnerJobDefaults.codeReviewsID

    private enum StepColumn {
        static let name = "name"
        static let environment = "environment"
        static let command = "command"
        static let condition = "condition"
    }

    private enum ProjectColumn {
        static let name = "name"
        static let path = "path"
        static let review = "review"
    }

    private let model: PartnerJobsEditorModel
    private let store: PartnerStore
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let settings: SettingsStore
    private let errorLine = NSTextField(wrappingLabelWithString: "")
    private var enabledModel: ComposableSettings.ViewModel<Bool>?
    private var guidelinesModel: ComposableSettings.ViewModel<String>?
    private var jobsChanges: AnyCancellable?
    /// One stable id per step, in step order. Internal for tests.
    ///
    /// A row is never named by its position: an edit in progress commits under the id it began with, and a
    /// step moved or removed meanwhile would otherwise take that edit into whichever step now has the index.
    /// Add, Remove and Up/Down carry the ids along with their steps; anything else that changes the steps
    /// (a reset, a write from elsewhere) issues fresh ones, so a stale edit finds no row and is dropped.
    private(set) var stepRowIDs: [String] = []

    /// Internal for tests.
    let stepsCard = ComposableSettings.EditableTableCard(
        title: "Steps",
        columns: [
            .init(id: StepColumn.name, title: "Name", width: 135, kind: .text(editable: true)),
            .init(id: StepColumn.environment, title: "Environment", width: 110, kind: .popUp,
                  fitsWidestChoice: true),
            .init(id: StepColumn.command, title: "Command", width: 260, kind: .text(editable: true)),
            .init(id: StepColumn.condition, title: "Condition", width: 200, kind: .text(editable: true))
        ],
        emptyMessage: "No steps. Add one with +.",
        visibleRows: 4,
        accessibilityPrefix: "settings.partner.job.steps")
    /// Internal for tests.
    let projectsCard = ComposableSettings.EditableTableCard(
        title: "Projects",
        columns: [
            .init(id: ProjectColumn.name, title: "Name", width: 140),
            .init(id: ProjectColumn.path, title: "Path", width: 300),
            .init(id: ProjectColumn.review, title: "Review", width: 70, kind: .toggle)
        ],
        emptyMessage: "No projects.",
        visibleRows: 8,
        accessibilityPrefix: "settings.partner.reviews.projects")
    /// The projects as last listed. Internal for tests.
    private(set) var listed: [PartnerToolSource.Project] = []

    public init(model: PartnerJobsEditorModel, store: PartnerStore,
                projects: @escaping @MainActor () -> [PartnerToolSource.Project],
                settings: SettingsStore = UserSettings.shared) {
        self.model = model
        self.store = store
        self.projects = projects
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Code Review",
            icon: NSImage(systemSymbolName: "checkmark.bubble", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["code review", "job", "guidelines", "steps", "crawl", "commits", "window", "interval", "concurrency",
         "branches", "reviewer", "model", "fix branch", "projects", "opt out", "reset"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Code review job",
                  body: "When the job is enabled, the partner crawls your projects for recent commits, reviews "
                      + "each one in a worktree of its own with /code-review, and commits the fixes on the fix "
                      + "branch. Nothing is pushed."),
            .init(title: "Guidelines and steps",
                  body: "Guidelines are saved to the job's file under the partner folder. A step is typed into a "
                      + "terminal or into Claude Code when its condition holds. The partner reads both when it "
                      + "starts, so edits apply the next time it does, or use Restart in the partner window."),
            .init(title: "Crawl interval",
                  body: "How often the crawl runs. Changing it rewrites the job's schedule and restarts its "
                      + "timer, which crawls at once."),
            .init(title: "Projects",
                  body: "Uncheck Review to leave a project out of the crawl. Reviews already queued for it stay.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(makeJobGroup())
        addStepsCard()
        addGroup(makeStepsResetGroup())
        addGroup(makeCrawlGroup())
        addGroup(makeReviewingGroup())
        addProjectsCard()
        reloadSteps()

        // A job written elsewhere (the coordinator following the crawl interval) shows here at once.
        // Guidelines being typed are not in the store yet and are left alone.
        jobsChanges = store.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == .jobs }
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.jobChangedElsewhere() } }
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        reloadProjects()
    }

    private var job: PartnerJob? { model.jobs.first { $0.id == Self.jobID } }

    // MARK: - Job

    private func makeJobGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Job")
        let enabled = ComposableSettings.ViewModel<Bool>(
            title: "Review landed commits",
            get: { [weak self] in self?.job?.isEnabled ?? false },
            set: { [weak self] isOn in self?.perform { try self?.model.update(Self.jobID) { $0.isEnabled = isOn } } },
            explanation: "Off, no commits are crawled or reviewed.")
        enabledModel = enabled
        let enabledView = ComposableSettings.CheckboxView(with: enabled)
        _ = enabledView.toggle.accessibilityID("settings.partner.job.enabled")
        group.addSettingSubview(enabledView)

        let guidelines = ComposableSettings.ViewModel<String>(
            title: "Guidelines",
            get: { [weak self] in self?.job?.guidelines ?? "" },
            set: { [weak self] text in
                self?.perform { try self?.model.saveGuidelines(jobID: Self.jobID, text: text) }
            })
        guidelinesModel = guidelines
        let editor = ComposableSettings.TextAreaEditView(
            with: guidelines, visibleLines: 12, monospaced: true, fitsContent: true)
        _ = editor.textView.accessibilityID("settings.partner.job.guidelines")
        group.addSettingSubview(editor)

        let reset = ComposableSettings.ButtonView(viewModel: ComposableSettings.ButtonViewModel(
            title: "Reset guidelines to default",
            explanation: "Restores the bundled guidelines and deletes your edited file.",
            wasPressedCallback: { [weak self] in
                self?.perform { try self?.model.resetGuidelines(id: Self.jobID) }
                self?.guidelinesModel?.revert()
            }))
        _ = reset.button.accessibilityID("settings.partner.job.reset-guidelines")
        group.addSettingSubview(reset)

        errorLine.textColor = .systemRed
        errorLine.isHidden = true
        group.addSettingSubview(errorLine)
        return group
    }

    private func jobChangedElsewhere() {
        model.reload()
        stepRowIDs = []
        enabledModel?.refresh()
        reloadSteps()
    }

    /// Runs one edit, showing its error under the card. Returns whether it saved.
    @discardableResult
    private func perform(_ work: () throws -> Void) -> Bool {
        errorLine.stringValue = ""
        errorLine.isHidden = true
        do {
            try work()
            return true
        } catch {
            Self.logger.error("Editing the code review job failed: \(error.localizedDescription)")
            errorLine.stringValue = "Could not save: \(error.localizedDescription)"
            errorLine.isHidden = false
            return false
        }
    }

    // MARK: - Steps

    private func addStepsCard() {
        stepsCard.fitsAllRows = true
        stepsCard.onAdd = { [weak self] in self?.addStep() }
        stepsCard.onRemove = { [weak self] rowID in self?.removeStep(rowID: rowID) }
        stepsCard.onEdit = { [weak self] rowID, column, text in self?.editStep(rowID: rowID, column: column, to: text) }
        stepsCard.onChoose = { [weak self] rowID, column, choice in
            self?.editStep(rowID: rowID, column: column, to: choice)
        }
        stepsCard.addFooterButton(title: "Up", identifier: "settings.partner.job.steps.up") { [weak self] in
            guard let rowID = self?.stepsCard.selectedRowID else { return }
            self?.moveStep(rowID: rowID, by: -1)
        }
        stepsCard.addFooterButton(title: "Down", identifier: "settings.partner.job.steps.down") { [weak self] in
            guard let rowID = self?.stepsCard.selectedRowID else { return }
            self?.moveStep(rowID: rowID, by: 1)
        }
        addGroup(stepsCard)
    }

    private func makeStepsResetGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Steps Defaults")
        let reset = ComposableSettings.ButtonView(viewModel: ComposableSettings.ButtonViewModel(
            title: "Reset steps to default",
            explanation: "Replaces every step with the bundled ones.",
            wasPressedCallback: { [weak self] in
                self?.perform { try self?.model.resetSteps(id: Self.jobID) }
                self?.stepRowIDs = []
                self?.reloadSteps()
            }))
        _ = reset.button.accessibilityID("settings.partner.job.reset-steps")
        group.addSettingSubview(reset)
        return group
    }

    /// Rows are listed in the order the steps run in, each under its stable id (`stepRowIDs`).
    func reloadSteps() {
        let steps = job?.steps ?? []
        if stepRowIDs.count != steps.count { stepRowIDs = steps.map { _ in UUID().uuidString } }
        let choices = ([.terminal, .claude] as [PartnerJobStep.Environment]).map {
            ComposableSettings.EditableTableChoice(id: $0.rawValue, title: $0.rawValue)
        }
        let rows = zip(stepRowIDs, steps).map { rowID, step in
            ComposableSettings.EditableTableRow(id: rowID, cells: [
                StepColumn.name: .text(step.name),
                StepColumn.environment: .choice(selected: step.environment.rawValue, choices: choices),
                StepColumn.command: .text(step.command),
                StepColumn.condition: .text(step.condition)
            ])
        }
        stepsCard.setRows(rows)
    }

    func editStep(rowID: String, column: String, to text: String) {
        guard let index = stepRowIDs.firstIndex(of: rowID) else {
            Self.logger.info("Dropped an edit to a step that is no longer listed")
            return
        }
        perform {
            try model.update(Self.jobID) { job in
                guard job.steps.indices.contains(index) else {
                    throw PartnerJobsEditorModel.EditorError.stepIndexOutOfRange(index)
                }
                switch column {
                case StepColumn.name: job.steps[index].name = text
                case StepColumn.command: job.steps[index].command = text
                case StepColumn.condition: job.steps[index].condition = text
                case StepColumn.environment:
                    if let environment = PartnerJobStep.Environment(rawValue: text) {
                        job.steps[index].environment = environment
                    }
                default: break
                }
            }
        }
        // A text cell already shows what was typed, and rebuilding the rows mid-edit can drop the editor.
        if column == StepColumn.environment { reloadSteps() }
    }

    func addStep() {
        if perform({ try model.addStep(to: Self.jobID) }) { stepRowIDs.append(UUID().uuidString) }
        reloadSteps()
        if let last = stepRowIDs.last { _ = stepsCard.selectRow(id: last) }
    }

    func removeStep(rowID: String) {
        guard let index = stepRowIDs.firstIndex(of: rowID) else { return }
        if perform({ try model.removeStep(in: Self.jobID, at: index) }) { stepRowIDs.remove(at: index) }
        reloadSteps()
    }

    /// Moves a step up (`offset` -1) or down (+1); its row keeps its id, so it stays selected.
    func moveStep(rowID: String, by offset: Int) {
        guard let index = stepRowIDs.firstIndex(of: rowID), stepRowIDs.indices.contains(index + offset) else {
            return
        }
        if perform({ try model.moveStep(in: Self.jobID, from: index, to: index + offset) }) {
            stepRowIDs.insert(stepRowIDs.remove(at: index), at: index + offset)
        }
        reloadSteps()
        _ = stepsCard.selectRow(id: rowID)
    }

    // MARK: - Reviewing

    private func makeCrawlGroup() -> ComposableSettings.GroupView {
        let settings = self.settings
        let crawl = ComposableSettings.GroupView(withTitle: "Crawl")
        crawl.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Review commits from the last (hours)", minValue: 1, maxValue: 24 * 30,
                get: { settings.get(UserSettings.partnerReviewsWindowHours) },
                set: { settings.set($0, for: UserSettings.partnerReviewsWindowHours) })),
            "settings.partner.reviews.window-hours"))
        crawl.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Crawl every (minutes)", minValue: 1, maxValue: 24 * 60,
                get: { settings.get(UserSettings.partnerReviewsCrawlIntervalMinutes) },
                set: { settings.set($0, for: UserSettings.partnerReviewsCrawlIntervalMinutes) },
                explanation: "The job's schedule.")),
            "settings.partner.reviews.crawl-interval"))
        crawl.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Include other local branches",
            get: { settings.get(UserSettings.partnerReviewsIncludeOtherBranches) },
            set: { settings.set($0, for: UserSettings.partnerReviewsIncludeOtherBranches) },
            explanation: "Off, only each project's default branch is crawled.")))
        return crawl
    }

    private func makeReviewingGroup() -> ComposableSettings.GroupView {
        let settings = self.settings
        let review = ComposableSettings.GroupView(withTitle: "Reviewing")
        review.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Reviews at once", minValue: 1, maxValue: 8,
                get: { settings.get(UserSettings.partnerReviewsConcurrency) },
                set: { settings.set($0, for: UserSettings.partnerReviewsConcurrency) },
                explanation: "Never more than one per project.")),
            "settings.partner.reviews.concurrency"))
        review.addSettingSubview(ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Reviewer model",
            get: { settings.get(UserSettings.partnerReviewsReviewerModel) },
            set: { settings.set($0, for: UserSettings.partnerReviewsReviewerModel) },
            explanation: "Passed to the reviewer's claude --model. Empty uses Claude Code's own default.")))
        review.addSettingSubview(ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Fix branch",
            get: { settings.get(UserSettings.partnerReviewsFixBranch) },
            set: { settings.set($0, for: UserSettings.partnerReviewsFixBranch) },
            explanation: "Fixes are committed here; other branches get this name plus their own.")))
        return review
    }

    /// Names a number field's text field, so accessibility can find and drive it.
    private func identified(_ view: ComposableSettings.IntegerFieldView,
                            _ identifier: String) -> ComposableSettings.IntegerFieldView {
        _ = view.textField.accessibilityID(identifier)
        return view
    }

    // MARK: - Projects

    private func addProjectsCard() {
        projectsCard.showsAddRemove = false
        projectsCard.onToggle = { [weak self] rowID, _, isOn in
            guard let self else { return }
            self.setReviewed(isOn, projectID: rowID)
            self.reloadProjectRows()
        }
        addGroup(projectsCard)
    }

    /// Re-reads the projects; ones without a path cannot be crawled and are left out.
    func reloadProjects() {
        listed = projects().filter { !$0.path.isEmpty }
        reloadProjectRows()
    }

    private func reloadProjectRows() {
        projectsCard.setRows(listed.map { project in
            ComposableSettings.EditableTableRow(id: project.id, cells: [
                ProjectColumn.name: .text(project.name),
                ProjectColumn.path: .text(project.path),
                ProjectColumn.review: .toggle(isReviewed(project.id))
            ])
        })
    }

    /// Whether the project is reviewed: anything but an explicit opt-out. Unreadable counts as reviewed here,
    /// since the crawl logs and skips it on its own.
    func isReviewed(_ projectID: String) -> Bool {
        do { return try store.reviewSetting(repoID: projectID, key: Self.optedOutKey) != "1" } catch {
            Self.logger.error("Reading a review opt-out failed: \(error.localizedDescription)")
            return true
        }
    }

    /// Opting back in deletes the setting rather than storing "0".
    func setReviewed(_ reviewed: Bool, projectID: String) {
        do {
            try store.setReviewSetting(repoID: projectID, key: Self.optedOutKey, value: reviewed ? nil : "1")
        } catch {
            Self.logger.error("Saving a review opt-out failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }
}
