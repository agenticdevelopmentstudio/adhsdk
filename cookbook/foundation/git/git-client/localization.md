
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| command-failed detail | `"git \(verb) exited with status \(exitStatus)."` (or with git's own detail appended) | The command-failed outcome's user-facing description |
| timed-out | `"git \(verb) did not finish within the configured timeout."` | The timed-out outcome |
| launch-failed | `"git \(verb) could not be run: \(reason)"` | The launch-failed outcome |
| executable-not-found | `"No git executable at \(path). Change it in Settings > Git."` | The executable-not-found outcome |
| invalid-argument | `"git \(verb) was not run: “\(argument)” begins with “-”, so git would read it as an option."` (or `"git \(verb) was not run: a name or commit is empty."`, or `"git \(verb) was not run: \(reason)"` when the reason is a sentence of its own) | The invalid-argument outcome |

Every string above is hardcoded English with no lookup table, ICU message,
or locale parameter anywhere in this component — there is no localization
mechanism here. This is a plain fact about the design, not a gap: a port to
a platform with an internationalization layer MUST decide, as a design
choice outside this contract, whether and how to route these five strings
through it.

