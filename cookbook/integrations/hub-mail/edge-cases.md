
- A message with no `internal_date` sorts after every dated message, and pages by id among its peers.
- A JSON column that arrives as a string (already encoded) is stored as that string; one that arrives as an array or object is encoded.
- A change for a column the projection does not know is ignored, so a new backend column does not break an old client.
- A `label_ids` value that is not valid JSON reads as no labels in every label filter, rather than failing the query.
- `applyLabels` skips a row id the mirror does not have, and a label both added and already present is not duplicated.
