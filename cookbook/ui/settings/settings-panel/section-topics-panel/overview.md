
The section topics panel is one sidebar topic of the settings window that
stands for a whole section. Inside it, a vertical topic list has one row per
panel in the section, beside the selected panel, the same topic and detail
split the Theme panel uses for its themes:

    Workspace  | Git        | <the selected panel>
               | Projects   |

It replaced a row of horizontal tabs. A tab bar stacked a second kind of
navigation over panels that already had a vertical one of their own, and ran
out of width at four tabs.

A section holding a single panel shows no list, because one row chooses
nothing; the panel fills the topic and the list returns when a second panel
arrives. Rows keep the order they are handed over in (the settings coordinator
hands them over alphabetised). The selected row survives a replacement of the
panels when its panel is still among the new ones.

The same file declares the container contract, `SettingsPanelContainer`: a
panel that holds other panels and shows one at a time. The window's search,
toolbar title, help and back and forward look through a container to the panel
the reader is actually looking at. This panel is the one conforming type. See
[adhsdk.ingredient.ui.settings.settings-panel-split](cookbook:ba8d9517-2528-4ae9-bc52-16046d68b126)
for the split it extends and
[adhsdk.ingredient.ui.settings.settings-panel](cookbook:432e8d4b-43c3-49fd-b481-036a759e7c55)
for the panel contract.

