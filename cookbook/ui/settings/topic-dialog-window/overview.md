
The topic dialog window is a modal dialog built as a settings window: the same
topic sidebar, toolbar and help drawer, resizable, with a problem line and
Cancel and OK buttons under the detail pane. The close button is Cancel,
Escape is Cancel and Return is OK. It is for editing one record in steps: the
topics are the steps, in the order given. See
[adhsdk.ingredient.ui.settings.settings-window](cookbook:7cac2263-94fe-47ec-ab1d-6cf5a12baf14)
for the window it extends.

It can be shown three ways. `present()` shows it app-modally. `beginSheet(on:)`
shows it as a sheet on one window, which holds up only that window; a sheet has
no toolbar, so its help is behind a standard round help button at the bottom
left. `show()` shows it as an ordinary window that holds up nothing and keeps
its toolbar and help drawer.

OK asks the owner's `validate` closure. A returned sentence stays in the dialog
as the problem line and the dialog stays open. With no problem, OK either
finishes the dialog (when `onOK` is unset) or hands over to `onOK`, for an owner
that saves asynchronously; that owner then calls `finish(true)` itself, or
shows a problem and re-enables OK. The dialog reports its one answer through
`onFinish`.

