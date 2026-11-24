
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` (JobsPane, JobPane) | `"customer"` or `"account"` | required on JobsPane | Who the caller is. The customer side creates jobs only from the catalog. |
| `jobId` (JobPane) | string | required | The job shown. |
| `runId` (JobRunPane) | string | required | The run shown. |
| `templateId` (JobTemplatePane) | string | required | The template edited. |
| `onOpenJob`, `onOpenRun`, `onOpenTemplate` | `(id: string) => void` | omitted | Lets a host make the open row URL-driven; omitted, selection is internal state. |

