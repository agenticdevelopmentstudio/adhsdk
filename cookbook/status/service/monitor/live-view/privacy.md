
Not applicable: the module stores and transmits nothing itself. It copies a service's `name`, `url`, `slug`, `environment` and probe error text into `StaleMonitor` rows for the `/live` response; those values originate upstream and are not inspected here.

