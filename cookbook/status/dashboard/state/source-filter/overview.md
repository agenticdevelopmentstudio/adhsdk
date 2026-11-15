
Source Filter is client-only state that holds which issue sources a filtered pane shows. The selectable sources are a fixed list of eight values (dns, http, glitchtip, vercel, vercel-runtime, cloudflare-pages, railway, crunchy). The selection starts with every source selected, and a toggle operation adds or removes one source. The selection is kept in browser local storage under a key the caller supplies, so it survives a reload. Separate uses with different keys share nothing.

It is described as the source-set toggle state shared by every filtered pane (active problems, recently resolved, activity), extracted so the three panes can't drift in how they filter. In the current source, the activity panel is the only consumer. It applies the filter only when more than one source exists and lets through rows with no platform.

Use it wherever a view needs a persisted, per-key multi-select over the fixed issue-source list. It has no visual surface of its own.

