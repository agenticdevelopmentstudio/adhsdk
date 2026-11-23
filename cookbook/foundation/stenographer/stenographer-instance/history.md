
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.0 | 2026-11-23 | Mike Fullerton | adhd's ports are reserved: reservedHTTPPorts is {22848, 22849, 22850, 22871} (review f2). |
| 1.1.1 | 2026-11-22 | Mike Fullerton | Retired the stenographerd port 22847: no default HTTP port, base URL or client address; a named instance may take 22847 (review f1). |
| 1.1.0 | 2026-11-22 | Mike Fullerton | The retired stenographerd's port 22847 is no longer reserved; reservedHTTPPorts is {22848, 22849}. |
| 1.0.1 | 2026-11-21 | Mike Fullerton | Resolved port-unique-across-instances: validate throws portTakenByAnotherInstance for a port another definition holds, checked after the instance overlap; added its description and vectors 041 to 044. |
