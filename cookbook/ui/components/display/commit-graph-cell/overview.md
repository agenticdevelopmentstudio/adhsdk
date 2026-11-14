
The commit list's graph column for one row: it draws one `Row` of the [commit graph layout](cookbook:750fe184-d20a-4b58-867b-3edd094d59b4) — the lines entering the row from its top edge, the lines leaving it from the commit's centre to its bottom edge, and the commit's node — in lane colours taken from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6)'s ANSI palette. It lays nothing out itself and knows nothing about git; a table cell hosts one per row and hands it the row the layout returned.

