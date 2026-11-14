
| ID | Requirements | Input | Expected |
|----|---|---|---|
| log-panel-001 | render-columns | columns=[{id:'level',title:'Level'},{id:'msg',title:'Message'}], showHeader=true | Header displays two cells with text 'Level' and 'Message' |
| log-panel-002 | render-rows | lines=[{id:'1',values:{level:{text:'info'},msg:{text:'Started'}}}], columns=[...] | One row with two cells displaying 'info' and 'Started' |
| log-panel-003 | show-empty-state | lines=[], emptyMessage='No logs' | Container displays text 'No logs' |
| log-panel-004 | enforce-max-lines | lines=[{id:'1',...},{id:'2',...},{id:'3',...}], maxLines=2 | Only rows with id '2' and '3' are visible; row id '1' is hidden |
| log-panel-005 | follow-tail-by-default | followTail=true (default), lines appended | The scroll container is scrolled to its maximum scrollable position (bottom) after new lines render |
| log-panel-006 | honor-follow-tail-toggle | followTail=true, user appends line, then followTail=false, user appends second line | First append scrolls to bottom; second append does not scroll |
| log-panel-007 | detect-user-scroll | followTail=true, user manually scrolls up so the distance from the bottom exceeds 4px, then a new line is appended | The scroll container does not scroll to the bottom for that append |
| log-panel-008 | handle-cell-click | `column={..., onCellClick: <mock function>}`, click cell | onCellClick is called with the LogLine object |
| log-panel-009 | handle-cell-double-click | `column={..., onCellDoubleClick: <mock function>}`, double-click cell | onCellDoubleClick is called with the LogLine object |
| log-panel-010 | apply-column-widths | columns=[{id:'a', width:200}, {id:'b', width:'1fr'}] | gridTemplateColumns is '200px 1fr' |
| log-panel-011 | apply-default-column-width | columns=[{id:'a'} (no width specified)] | gridTemplateColumns includes 'minmax(120px, 1fr)' for that column |
| log-panel-012 | apply-cell-text-alignment | column={align:'center'}, cell text 'Centered' | CSS textAlign is set to 'center' |
| log-panel-013 | apply-cell-level-color | cell={level:'error'}, column={defaultLevel:'info'} | Cell color matches the 'error' row of the Level Colors table |
| log-panel-014 | apply-cell-custom-color | cell={color:'#ff0000'} | CSS color is '#ff0000' (overrides level color) |
| log-panel-015 | apply-cell-mono-font | cell={mono:true} | fontFamily is 'var(--font-mono, ui-monospace, SFMono-Regular, monospace)' |
| log-panel-016 | apply-cell-strong-weight | cell={strong:true} | fontWeight is 600 |
| log-panel-017 | apply-cell-link-styling | cell={link:true} | CSS class 'lp-cell--link' is present |
| log-panel-018 | show-interactive-indicator | column={onCellClick: () => {}}, cell | CSS class 'lp-cell--interactive' is present |
| log-panel-019 | apply-cell-title-attribute | cell={text:'Error message'} | title attribute on cell div is 'Error message' |
| log-panel-020 | support-max-height | maxHeight='500px' | Body container has CSS maxHeight: '500px' |
| log-panel-021 | support-custom-class | className='custom-log' | Root container has class 'lp-root custom-log' |
| log-panel-022 | apply-grid-layout | columns with widths=[200, '1fr', 100] | gridTemplateColumns is '200px 1fr 100px' on both header and rows |
| log-panel-023 | include-aria-roles | Standard render | Header has role='row', columns have role='columnheader', rows have role='row', cells have role='cell', rows list has role='rowgroup' |
| log-panel-024 | stop-event-propagation | Cell has onCellClick defined and is nested inside a parent element with its own click handler; click the cell | onCellClick is invoked; the parent element's click handler is not invoked (the event does not bubble to it) |
| log-panel-025 | render-columns | columns=[...], showHeader=false | No header row is rendered |
| log-panel-026 | show-empty-state | lines=[], emptyMessage not provided | Container displays text '(no events)' |
| log-panel-027 | enforce-max-lines | lines=[{id:'1',...},{id:'2',...}], maxLines=0 | Zero rows are visible; empty message is shown |
| log-panel-028 | honor-follow-tail-toggle | followTail=false, user scrolled away from the bottom, then followTail=true, line appended | The next append scrolls the container to the bottom |
| log-panel-029 | apply-cell-mono-font | cell={mono: undefined}, column={defaultMono:true} | fontFamily is 'var(--font-mono, ui-monospace, SFMono-Regular, monospace)' |
| log-panel-030 | apply-cell-mono-font | cell={mono:false}, column={defaultMono:true} | fontFamily is not set to the monospace stack |
| log-panel-031 | apply-cell-level-color | cell has no level, column={defaultLevel:'warn'} | Cell color matches the 'warn' row of the Level Colors table |
| log-panel-032 | apply-cell-level-color | cell has no color or level, column has no defaultLevel | No inline color is set; text inherits |
| log-panel-033 | support-max-height | maxHeight=300 (number) | Body container has CSS maxHeight of 300px |
| log-panel-034 | enforce-max-lines | 3 lines, maxLines=-1 | Zero rows are visible; empty message is shown |
| log-panel-035 | enforce-max-lines | 3 lines, maxLines=NaN | All 3 rows are visible |
| log-panel-036 | enforce-max-lines | 3 lines, maxLines=1.5 | The last 2 rows are visible (the fractional slice start truncates toward zero) |
| log-panel-037 | stop-event-propagation | Cell with no onCellClick, nested in a parent with its own click handler; click the cell | The parent's click handler is invoked (the event bubbles) |
| log-panel-038 | handle-cell-double-click | Column defines both onCellClick and onCellDoubleClick; double-click a cell | onCellClick is called for the preceding clicks and onCellDoubleClick is called with the LogLine |
| log-panel-039 | apply-cell-title-attribute | cell={text:'<b>x</b>'} | The cell shows the literal text `<b>x</b>` and contains no `<b>` element |
| log-panel-040 | apply-cell-text-alignment | column={align:'end'} | Header cell and body cells both have textAlign 'end' |
| log-panel-041 | show-interactive-indicator | column={isClickable:false}, no onCellClick, cell.link not set | CSS class 'lp-cell--interactive' is absent |
| log-panel-042 | show-interactive-indicator | column defines only onCellDoubleClick | CSS class 'lp-cell--interactive' is absent |
