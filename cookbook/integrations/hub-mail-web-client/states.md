
- **empty**: no pull has run; the first read starts one.
- **pulling**: a pull is in flight; reads wait on it.
- **ready**: the snapshot reflects the hub as of the remembered cursor.
- **failed**: the last pull rejected; the snapshot holds what it held before, and the next read retries.

