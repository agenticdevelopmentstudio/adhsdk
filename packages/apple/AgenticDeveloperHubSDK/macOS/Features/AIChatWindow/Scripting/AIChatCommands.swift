import AppKit
import AgenticDeveloperHubSDKCore

@MainActor
private var coordinator: AIChatCoordinator? {
    NSApp.scriptingHost?.feature(AIChatCoordinator.self)
}

@objc(ShowAIChatCommand)
public final class ShowAIChatCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        coordinator?.showWindow()
        return nil
    }
}

@objc(HideAIChatCommand)
public final class HideAIChatCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        // Close, not order out: a chat that is only hidden keeps its session and
        // its ai-chat-N slot, and no command or menu can reach it again.
        coordinator?.windowController?.close()
        return nil
    }
}

@objc(SendChatMessageCommand)
public final class SendChatMessageCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let text = directParameter as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Message text is required."
            return nil
        }
        guard let aiChat = coordinator else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "AI Chat is not available."
            return nil
        }
        // Say what the fix is rather than build a chat that has nothing to talk to.
        guard !UserSettings.aiProviderConfigurations.value.isEmpty else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "No AI connection is configured. Add one in Settings > AI Connections."
            return nil
        }
        let createdChat = aiChat.windows.isEmpty
        aiChat.ensureWindow()
        guard let viewModel = aiChat.viewModel else {
            // Never leave behind a hidden chat this command made and cannot use.
            if createdChat { aiChat.windowController?.close() }
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Could not create chat view model."
            return nil
        }
        viewModel.sendMessage(text)
        return viewModel.messages.count
    }
}

@objc(GetChatMessagesCommand)
public final class GetChatMessagesCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let viewModel = coordinator?.viewModel else { return [] }
        return viewModel.messages.map { "\($0.role.scriptingLabel): \($0.text)" }
    }
}

@objc(ClearChatCommand)
public final class ClearChatCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        coordinator?.viewModel?.clearHistory()
        return nil
    }
}
