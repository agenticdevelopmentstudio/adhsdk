
- **Data collected**: None by the reader. Its purpose is to stop the message's sender from collecting a read signal.
- **Storage**: Nothing is persisted: the body view's website data store is non-persistent. The compiled content rule list is kept by WebKit's rule list store under "mail-reader-block-remote".
- **Transmission**: While remote content is blocked, the reader makes no request to any remote host; the policy and the rule list both stop it. After "Load Remote Images", the message's remote loads leave the device, for that message only.
- **Retention**: Not applicable: the reader keeps no data beyond the on-screen message.

