
`SessionDaemonConfiguration` is everything that makes one session daemon's runtime its own: names, paths, intervals and the Claude Code hook registration it installs (Claude Hook Configuration ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871))). The runtime and the retention service read it; their own behavior is not specified here. A daemon builds one and hands it to the session runtime (`SessionDaemonRuntime`); nothing in the shared code spells a daemon's name or directory itself.

It is a `Sendable` struct of `var` fields with one initializer that derives several defaults from other arguments, and one static factory, `test(port:root:)`, that roots every path and the hook's `settings.json` under a directory so a test never touches the real Claude Code settings.

