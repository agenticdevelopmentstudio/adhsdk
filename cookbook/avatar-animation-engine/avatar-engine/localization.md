
Not applicable: the engine stores and echoes caller-supplied or
config-supplied strings verbatim (`say(text)`; the lines `randomSaying`
draws from `config.sayings.sayings`) with no locale-aware formatting,
pluralization, or string-table lookup of its own. Localizing the sayings
data is the config author's concern; `sayings.json` is external content, not
part of this ingredient's source files.

