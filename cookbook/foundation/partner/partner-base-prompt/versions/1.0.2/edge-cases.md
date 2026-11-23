
- **Empty and missing input**: An empty jobs array, or one with no enabled job, yields exactly `text`. An empty `guidelines` yields a job heading followed by a blank line and nothing else; an empty job `name` yields the heading `## Job: ` with nothing after it.
- **Duplicate jobs**: The same job passed twice is listed twice; the function does not de-duplicate.
- **Special characters in a step**: A name, command or condition containing backticks, newlines or markdown is inserted unescaped, so a command containing a backtick can end the code span early in the rendered prompt; the source does not guard against it.
- **Condition whitespace**: A condition that is empty or only whitespace and newlines is omitted; a condition with internal newlines keeps them.
- **Job id in the skill name**: The `name` field takes `job.id` verbatim, with no quoting or sanitising, unlike the job name in the description; an id containing spaces, colons or newlines would produce invalid or altered frontmatter. Built-in ids such as `code-reviews` are plain.
- **Job name escaping order**: Backslashes are escaped before quotes and newlines, so the escapes added for quotes and newlines are not themselves doubled.
- **Guidelines containing `---`**: Guidelines are inserted verbatim after the frontmatter, so a `---` line in them is not escaped.
- **Concurrent access**: All members are pure static functions over immutable values, so any thread may call them at once.
- **Error states and offline state**: Not applicable: the functions neither throw nor perform I/O.
- **Boundary values**: There is no limit on the number of jobs, steps or the length of any string; prompt size is the caller's concern.

