
- A connection with no messages yet lists with no messages, not an error.
- A message row for a connection the caller no longer has stays in the snapshot but is never listed, because messages are always read by account.
- A pull that ends mid-way with an error keeps the changes already applied and the cursor of the last applied page, so the retry continues from there.
- Two equal `internal_date` values order by id descending.

