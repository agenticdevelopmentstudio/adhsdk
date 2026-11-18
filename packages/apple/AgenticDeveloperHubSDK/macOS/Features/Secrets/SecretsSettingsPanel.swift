import AppKit
import AgenticDeveloperHubSDKCore

/// Settings > Features > Secrets: when the window locks itself
/// (``SecretsLockPolicy``), and in Debug builds only the switch onto a file
/// of testing words (``PrivacyTestingWords``). The window itself opens from
/// Window > Show Secrets Window and the privacy toolbar's Secrets button.
///
/// The Secrets window's gear shows the same panel in a popover.
@MainActor
public final class SecretsSettingsPanel: ComposableSettings.SettingsPanelViewController {

    static let lockInactiveIdentifier = "settings.secrets.lock.app-inactive"
    static let lockSleepIdentifier = "settings.secrets.lock.sleep"
    static let lockIdleIdentifier = "settings.secrets.lock.idle"
    static let testingWordsIdentifier = "settings.secrets.testing-words"
    static let testingWordsPathIdentifier = "settings.secrets.testing-words-path"

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Secrets",
            icon: NSImage(systemSymbolName: "key", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["secrets", "privacy words", "private words", "lock", "sleep", "idle", "inactivity",
         "background", "password", "terminal", "conceal", "stand-in"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Private Words",
                body: "The words are one list, kept in the keychain and shared by the web "
                    + "browsers' privacy and the private terminals. Each word can be turned off "
                    + "without deleting it. Sites says where on the web it applies, as "
                    + "comma-separated patterns: * is every page; google.com/* every page on "
                    + "google.com; foo.com/hi/* the pages under foo.com/hi; *.google.com any "
                    + "host ending in .google.com. Terminal says which private terminals it "
                    + "applies in, as .gitignore patterns over the directory each terminal "
                    + "started in: * is every one; a name such as adkitchen is any directory of "
                    + "that name and everything inside it; a pattern with a slash is anchored at "
                    + "the root of the disk, ~ being your home folder, so ~/work/** is "
                    + "everything under ~/work; ! takes a directory back out, and the last "
                    + "pattern that matches decides. An empty Terminal is no terminal. "
                    + "Every change is saved as you make it; a row with only one of its two "
                    + "words is tinted and saved once it has both."
            ),
            .init(
                title: "The Secrets Window",
                body: "Open it from Window > Show Secrets Window, or from Secrets in a web "
                    + "browser's privacy toolbar. It opens with its contents hidden behind an "
                    + "eye with a line through it; Unlock Secrets asks you to authenticate. "
                    + "Turning testing words on or off locks it again, so the other words need "
                    + "authenticating too. While it is not the front "
                    + "window its contents are hidden the same way. The eye in its toolbar hides "
                    + "them until pressed again; the lock hides them and needs you to "
                    + "authenticate before they show again. Nothing outside the app can read "
                    + "the words off it: it is closed to accessibility, and while the words "
                    + "show it is left out of screenshots and screen sharing."
            ),
            .init(
                title: "Locking",
                body: "The Secrets window locks itself when the app goes to the background, "
                    + "when the Mac sleeps, its display sleeps, its screen locks or you switch "
                    + "users, and after the chosen number of minutes without a key press, "
                    + "click or scroll anywhere in the app, whether the window is in front or "
                    + "not. Each can be turned off here."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(makeLockingGroup())
        #if DEBUG
        if PrivacyTestingWords.isAvailable { addGroup(makeTestingWordsGroup()) }
        #endif
    }

    private func makeLockingGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Locking")
        let inactive = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Lock when the app is in the background",
            setting: UserSettings.secretsLockWhenAppInactive))
        _ = inactive.toggle.accessibilityID(Self.lockInactiveIdentifier)
        group.addSettingSubview(inactive)

        let sleep = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Lock when the Mac sleeps or its screen locks",
            setting: UserSettings.secretsLockOnSleep))
        _ = sleep.toggle.accessibilityID(Self.lockSleepIdentifier)
        group.addSettingSubview(sleep)

        let idle = ComposableSettings.PopupMenuChoiceView(viewModel: ComposableSettings.ChoiceViewModel<Int>(
            title: "Lock after inactivity",
            setting: UserSettings.secretsLockAfterIdleMinutes,
            choices: UserSettings.secretsIdleMinuteChoices.map { minutes in
                .init(label: Self.idleLabel(minutes), value: minutes)
            }))
        _ = idle.accessibilityID(Self.lockIdleIdentifier)
        group.addSettingSubview(idle)
        return group
    }

    static func idleLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: "Never"
        case 1: "1 minute"
        default: "\(minutes) minutes"
        }
    }

    #if DEBUG
    /// Debug builds only: the switch onto a JSON file of testing words and
    /// the file's path (``PrivacyTestingWords``).
    private func makeTestingWordsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Testing Words")
        let enabled = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Use testing words", setting: UserSettings.privacyTestingWordsEnabled))
        _ = enabled.toggle.accessibilityID(Self.testingWordsIdentifier)
        group.addSettingSubview(enabled)

        let path = ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Testing words file", setting: UserSettings.privacyTestingWordsPath))
        path.textField.placeholderString = "~/privacy-testing-words.json"
        _ = path.textField.accessibilityID(Self.testingWordsPathIdentifier)
        group.addSettingSubview(path)
        return group
    }
    #endif
}
