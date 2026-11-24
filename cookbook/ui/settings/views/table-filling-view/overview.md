
The table filling view holds one editable table card at the top, as wide as
itself, and gives the card's table whatever height is left. The table then
grows and shrinks with the window and never draws empty rows below a short
card. The card keeps a fixed height by design; telling it the height is this
view's job. See
[adhsdk.ingredient.ui.settings.views.editable-table-card](cookbook:9016cb03-9682-404f-b787-c271039f25b3)
for the card.

It is used wherever a settings panel or editor is mostly one table: the excluded
files panel, the privacy words editor, the browser engine panels and the Safari
extensions panel.

