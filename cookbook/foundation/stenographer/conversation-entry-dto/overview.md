
`ConversationEntryDTO` is one line of the conversation between a human and an observed Claude session, extracted from the captured transcript (`transcript_lines`) rather than from any summarization pass. The Conversations window renders these as a group chat: every observed session's dialogue interleaved on one timeline, each row labelled with the project, branch and session name it came from.

Attribution (`projectName`, `gitBranch`, `sessionName`, `termProgram`) travels with the entry rather than being looked up per row, because the feed spans many sessions and the join that supplies it costs nothing at query time.

The type is an immutable `Codable`, `Sendable`, `Equatable` struct that crosses the app-to-daemon boundary over XPC and HTTP. It has a hand-written tolerant `Decodable` because the app and daemon are installed separately, so an app can be newer than the daemon answering it. Two derived members fold the `kind` vocabulary: `isFromUser` and `isWorkOutput`, plus the static `workOutputKinds` set.

