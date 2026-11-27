
The users pane shows customers' emails, names, roles and storage to the product's own admins only. The roster is existence, not content. Who may read it is the backend's decision, made per request.
- **Consented support access**: the Support page lets a product admin, once a customer approves, read that customer's content in a read-only viewer. The customer grants it, for a length they were told, every read is logged, and the backend requires a second factor from a recent sign-in for each request and opening.
- **Jobs status only**: the `/admin/jobs` page shows a product's run status, never a run's inputs, outputs or logs ([jobs-status-no-content](#requirements/jobs-status-no-content)); reading those needs a support grant.

