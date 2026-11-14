
`ThemeStorage` makes no log call. `UserDefaultsThemeStorage` logs at error level through its `Loggable` logger (`makeLogger()`), once when the stored custom-themes blob cannot be decoded (it reads an empty catalog) and once when a custom-themes write cannot be encoded (the stored catalog is unchanged), each with the error's `localizedDescription` marked public. It logs nothing on a successful read or write or on an external change.

