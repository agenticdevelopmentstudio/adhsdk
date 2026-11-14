
The class conforms to `Loggable`. It logs at error level when the stored catalog fails to decode (the read returns an empty array) and when a catalog fails to encode (the write is dropped). The source logs the error description with public privacy. It was not verified that a decode or encode error description holds no user data, since a decoding error can echo a key path or a value, so a port SHOULD log it as private.

