
The worker holds `workerData.db.authToken`, a credential for remote libSQL, in memory and passes it to `openLibsql`; it never logs, posts or stores it, and the startup failure reply carries only an error message. The database file itself holds the application's stored data; where that is stored (the `file:` path) and how it leaves the device are decided by the host and by the `Storage` implementation, not by this file.

