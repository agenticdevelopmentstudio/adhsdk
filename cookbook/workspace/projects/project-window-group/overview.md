
A project window, as the user sees it, is one window with a list of active
projects and one of them on screen. `ProjectWindowGroup` is the model behind
that window. It holds the ordered list of active repository ids
(`activeRepoIDs`), which one is on screen (`selectedRepoID`), which panel the
window's shelf shows (`panel`) and what each panel's filter field holds
(`filterText`).

Underneath, each active project keeps a window of its own and the group shows
exactly one of them, swapping which one in place, so switching is instant. With
no project active the group shows an empty project window. Every window in the
group has its own shelf and every shelf reads this one object, so the panel,
the active list and the filter text are the same whichever window is on
screen. The window machinery itself (the window controllers, the swap) is
outside this component; this recipe covers the model and its persisted record.

Three types are specified together:

- `ProjectShelfPanel`: the shelf panels (`browser`, `activeProjects`), each with
  a title, an SF Symbol name and a filter placeholder.
- `ProjectWindowState`: one window as persisted (the `UserSettings.projectWindows`
  entry).
- `ProjectWindowGroup`: the live main-actor `ObservableObject`.

