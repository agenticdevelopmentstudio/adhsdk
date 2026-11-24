
- **Data collected**: The branch name in the clear and, for status and recent commits, only a length and a hash; no file name or commit message is kept, which is the reason for fingerprinting.
- **Storage**: None by this type; the enriched payload is passed on to the daemon.
- **Transmission**: None; commands read the local repository and the result goes to a local daemon.
- **Retention**: Not applicable here; the consumer decides.

The branch name can itself carry meaning (a ticket id or a person's name), and a hash of a short or guessable status text can be reversed by trying candidates, so it is not an anonymisation.

