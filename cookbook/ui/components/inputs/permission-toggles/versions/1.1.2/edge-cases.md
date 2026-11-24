
- **Parent disallows all capabilities**: `parent={create: false, read: false, update: false, delete: false}`. All four buttons render disabled. User cannot enable any capability. `onChange` is never called. (perm-015)
- **Value violates parent constraint before mount**: `value={create: true, read: true, update: true, delete: true}` but `parent={create: false, read: true, update: true, delete: true}`. The component does not correct the value prop; it only prevents further violations via user interaction. The C button appears off due to the condition `on = value[key] && !blockedByParent`. The parent ceiling is enforced on toggle, not retroactively on render — see **clamp-emitted-values**. (perm-008)
- **Parent is undefined**: When `parent` is not provided, all capabilities are treated as unrestricted. `blockedByParent` is false for all buttons. (perm-016)
- **Disabled and blocked simultaneously**: When `disabled={true}` and a capability is also `blockedByParent`, both conditions suppress the button. The behavior is identical to either condition alone. (perm-017)
- **Rapid clicks**: Clicking a button invokes `toggle()` synchronously, calling `onChange` immediately. Multiple rapid clicks generate multiple `onChange` calls without debouncing. (perm-018)
- **Unmount during transition**: The transition-colors CSS class applies to color changes. If the component unmounts, the transition is interrupted but causes no error. (perm-019)

