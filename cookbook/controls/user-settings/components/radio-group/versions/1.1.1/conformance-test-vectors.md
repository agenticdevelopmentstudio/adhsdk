
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| radio-group-001 | render-choices | choices=[{value:'a',label:'A'},{value:'b',label:'B'}] | Both choices rendered as radio options |
| radio-group-002 | maintain-selection-state | choices=[{value:'a',...},{value:'b',...}], value='b' | The choice with value='b' renders with checked=true |
| radio-group-003 | handle-value-change | choices=[{value:'a',label:'A'},{value:'b',label:'B'},{value:'c',label:'C'}]; user clicks choice with value='c' | onChange callback invoked with value='c' |
| radio-group-004 | fieldset-root | Component rendered | Root element is a fieldset |
| radio-group-005 | legend-label | label='Group Label' provided | Legend element renders with text 'Group Label' |
| radio-group-006 | radiogroup-role | Component rendered | Container element has role="radiogroup" |
| radio-group-007 | choice-labels | choices=[{value:'a',label:'Option A'}] | Text 'Option A' appears next to radio input |
| radio-group-008 | choice-hints | choices=[{value:'a',label:'A',hint:'Hint text'}] | 'Hint text' rendered adjacent to the choice |
| radio-group-009 | field-hint | hint='Field guidance' | Text 'Field guidance' rendered below the radio choices |
| radio-group-010 | disabled-state | disabled=true, choices=[{...},{...}] | All radio inputs have disabled attribute; fieldset has disabled attribute |
| radio-group-011 | individual-choice-disable | choices=[{value:'a',...},{value:'b',disabled:true}] | Choice 'b' radio input has disabled attribute; choice 'a' remains enabled |
| radio-group-012 | custom-classname | className='custom-class' | Root fieldset renders with 'custom-class' in its class list |
| radio-group-013 | generated-name | Two RadioGroup instances rendered, neither given a name prop | Each instance's own radio inputs share one name within that instance; the two instances' generated names differ from each other and neither is empty |
| radio-group-014 | provided-name | name='my-group' | All radio inputs have name="my-group" |
| radio-group-015 | render-choices | choices=[] | Fieldset and radiogroup div render; no radio inputs render |
| radio-group-016 | legend-label | label=undefined | No legend element renders |
| radio-group-017 | field-hint | hint=undefined | No field-level hint element renders |
| radio-group-018 | choice-hints | choices=[{value:'a',label:'A'}] (no hint property) | No hint element renders for that choice |
| radio-group-019 | maintain-selection-state | choices=[{value:'a',...},{value:'b',...}], value='z' | No radio input renders as checked |
| radio-group-020 | disabled-state | disabled=true; user attempts to click a choice | onChange is never invoked |
| radio-group-021 | maintain-selection-state | value='b' selected; the choices array is replaced by a new array that still contains value 'b' | Choice 'b' still renders as checked |
| radio-group-022 | maintain-selection-state | value='b' selected; the choices array is replaced by a new array that no longer contains value 'b' | No choice renders as checked, until onChange updates value |

