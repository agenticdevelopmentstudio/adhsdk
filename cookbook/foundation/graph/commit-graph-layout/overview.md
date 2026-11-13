
The lane layout behind a commit history's graph column. Given commits newest first, each with its parent IDs, it places every commit in a column, gives it a lane (a colour index) and describes the line segments to draw in its row: from the row's top edge to the commit's centre, and from the centre to the bottom edge. It is pure Foundation, generic over the commit ID, and stateful so a history loaded page by page lays out exactly as it would in one pass. A view draws from the rows; it never re-derives the layout.

