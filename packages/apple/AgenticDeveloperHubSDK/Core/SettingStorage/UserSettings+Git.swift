import Foundation

extension UserSettings {
    /// Absolute path of the git executable every toolkit git call runs.
    public static var gitExecutablePath = UserSetting<String>("git.executable_path", default: "/usr/bin/git")

    /// Wall-clock budget, in seconds, for one git invocation.
    public static var gitStatusTimeoutSeconds = UserSetting<Int>("git.status_timeout_seconds", default: 5)

    /// When false, `git status` runs with `--ignore-submodules`.
    public static var gitStatusIncludesSubmodules = UserSetting<Bool>(
        "git.status_includes_submodules",
        default: false
    )

    /// The diff's layout: `inline` or `sideBySide`.
    public static var gitDiffLayout = UserSetting<String>("git_diff_layout", default: "inline")

    /// When true, the diff asks git to ignore whitespace changes.
    public static var gitDiffIgnoreWhitespace = UserSetting<Bool>("git_diff_ignore_whitespace", default: false)

    /// When true, the diff emphasises the changed words of each paired removed and added line.
    public static var gitDiffWordHighlight = UserSetting<Bool>("git_diff_word_highlight", default: true)
}
