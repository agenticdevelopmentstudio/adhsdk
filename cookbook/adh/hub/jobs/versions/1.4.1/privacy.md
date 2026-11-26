
- **Data collected**: Job inputs, step definitions, step outputs and logs, trigger settings, and an
  environment's reported capabilities. These are the owner's content.
- **Storage**: Server side. An inbound secret and an environment token are shown once, are stored by the
  backend only as a hash, and are never read back. The client keeps lists in an in-memory cache only.
- **Product admin**: `JobStatusPane` reads only the status aggregate, which carries no inputs, steps,
  outputs or logs. Reading content needs a support grant.
- **Retention**: A backend matter; deleting a job archives it and keeps its runs.

