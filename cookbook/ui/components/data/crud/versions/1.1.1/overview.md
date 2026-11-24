
The Crud data model represents four independent permission capabilities: create, read, update, and delete. It is used across the platform wherever permission sets are managed — application→schema grants, bucket access grants, and other access-control contexts. The model provides three core capabilities: definition via independent boolean flags, defaults for the most-restrictive and read-only access patterns, and a parent-clamping utility to ensure child permissions never exceed a parent's permissions.

