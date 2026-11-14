
The class conforms to `Loggable`. It logs at error level when the stored catalog fails to decode (the read returns an empty array) and when a catalog fails to encode (the write is dropped). The error description is logged as public; it holds no user data beyond the theme shape.

