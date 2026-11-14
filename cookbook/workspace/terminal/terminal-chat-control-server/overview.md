
This source holds two main-actor types that let a process outside the app drive the app's Terminal Chats, over the protocol [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988) defines. The client is `adterm`, run by Claude Code in another terminal: it lists the chats, types a command into one and reads the reply.

`TerminalChatDirectory` is the set of Terminal Chats the app has open, by id. A chat pane adds itself when it is made and removes itself when it is discarded; sessions are held weakly besides, so a pane that goes without saying so drops out instead of lingering. Each entry pairs a listing (a short stable id, the project name, the directory and the pane number) with the chat session.

`TerminalChatControlServer` listens on a Unix-domain socket named for the process id and answers one JSON request per connection from the directory. Everything goes through the chat, never the terminal, so it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with its privacy words in place of the real ones. The transport is `UnixSocketLineServer`: it makes the socket file owner-only, refuses a peer whose user id is not the server's own, reads one newline-delimited line per connection and answers with one line.

