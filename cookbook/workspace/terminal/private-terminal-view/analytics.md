
Not applicable: the view contains no analytics call. The session that owns it signals input and output activity from the themed view's `onDataSent` and `onDataReceived` callbacks, which this view does not touch; they fire only for bytes the view actually forwards, so held bytes raise no activity until they are released.

