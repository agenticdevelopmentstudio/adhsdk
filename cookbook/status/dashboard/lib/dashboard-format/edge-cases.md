
- **Null and empty input — site list**: a `null` site and an empty list MUST give an empty copy; `undefined` body and a body with no `views` MUST give `null` from the listed-sites function, which callers read as "nothing to show."
- **Null and empty input — reports**: an empty reports object MUST give the `none` value for any site, including the empty string.
- **Boundary — vitals at 1000**: exactly `1000` MUST be written `1.0s`; `999.4` MUST be written `999ms`; `999.5` and above rounds to `1000ms` because the comparison runs on the raw value.
- **Boundary — day buckets near midnight UTC**: a timestamp one millisecond before midnight UTC MUST label the earlier day, whatever the viewer's zone is.
- **Malformed input — timestamps**: an unparseable timestamp makes the bucket functions throw; callers pass timestamps the server produced, and nothing here catches the error.
- **Malformed input — range**: any range other than `"24h"` takes the day format, so an unknown range string is formatted like `"7d"`.
- **Malformed input — site names**: names from a URL are used as given; the report lookup is protected against inherited property names, but the module does no decoding, trimming or case folding.
- **Concurrent access**: not applicable — the functions are pure and hold no state beyond two immutable formatters, so any number of calls may run in any order.
- **Error states and offline**: not applicable — the module performs no I/O and has no dependency that can fail or disconnect.
- **Cancellation and timeouts**: not applicable — every call completes synchronously.
- **Locale**: the sort in the with-site function uses the runtime's default locale, so the order of non-ASCII or mixed-case names can differ between runtimes; the date formatters are fixed to English and UTC.

