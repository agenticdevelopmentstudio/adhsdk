
`HookDropWriter` is where a hook helper writes its drop files and how it writes them. A drop file is the hook helper's fallback transport: when no daemon is listening, the envelope lands in the configuration's drop directory and the daemon scans it in later.

The type is a caseless enum with three public static functions. `dropDirectoryVariable` names the environment variable that overrides the directory for one configuration. `dropDirectory` picks the override when it is set and non-empty, otherwise the configuration's own directory. `writeDropFile` encodes an envelope and puts it in a directory as a new, uniquely named JSON file, written to a temporary name first and then renamed so that a scanner never sees a half-written file.

It is called by the hook capture command (HookCaptureCommand ([adhsdk.ingredient.foundation.claude-hooks.hook-capture-command](cookbook:826153e3-cae8-4917-a1d3-c298a54ab558))) and by the status-line feed (StatusLineCapture ([adhsdk.ingredient.foundation.claude-hooks.status-line-capture](cookbook:704d4ae9-e344-44d4-b19c-eadfec082077))) when the daemon refuses a post. Both pass the environment explicitly, which is how tests redirect output to a temporary directory.

