
- A configuration whose template no longer resolves (the plugin was removed
  or the template renamed): the editor shows the Name row only and is titled
  with the configuration's name; deleting it still clears its stored key
  through the plugin's shared fields (**providers-panel-remove-clears-values**).
- A rename to empty or whitespace-only text: ignored; the stored name stays
  (**providers-panel-rename**).
- A rename to a name another configuration already has: the name is made
  unique (**providers-panel-rename**).
- The Test Chat chooses a model: it writes the same model setting the
  "Default Model" row shows, and the row refreshes
  (**providers-editor-default-model-row**).
- The − button pressed with nothing selected: the panel refuses with the
  platform's refusal feedback and asks nothing
  (**providers-panel-remove-confirm**).
- The deleted configuration was the first row: selection moves to the new
  first row; when it was the last configuration, nothing is selected and −
  is disabled.
