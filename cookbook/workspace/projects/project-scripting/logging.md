
This surface and the three wrapper types make no logging call. A branch
that fails to resolve is not logged here at all; any underlying git
failure is recorded once, upstream, by the git command log (see
[adhsdk.ingredient.workspace.projects.branch-controller](cookbook:92f11498-2cb2-4b04-92b9-560d9f2de6ee)), not a
second time by this surface.

| Event | Level | Message |
|-------|-------|---------|
| (none) | — | This surface and its three wrapper types emit no log messages. |

