
- **empty**: no pull has run; the first read starts one.
- **pulling**: a pull is in flight; reads wait on it.
- **ready**: the snapshot reflects the hub as of the remembered cursor.
- **failed**: the last pull rejected; the snapshot keeps whatever pages were applied before the failure, with the cursor of the last applied page, and the next read retries from there.

