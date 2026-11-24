
**Report shape**

- **report-fields**: `DaemonHealthReport` MUST carry `status` (String), `version` (String), `uptimeSeconds` (TimeInterval) and `strategy` (a `DaemonStrategyReport`), and MUST be `Codable`, `Sendable` and `Equatable`.
- **status-opaque**: `DaemonHealthReport.status` MUST be a free String that the report does not interpret; it MUST NOT be an enum.
- **strategy-fields**: `DaemonStrategyReport` MUST carry `name` (String), `kind` (String), `workUnits` (an array of `DaemonWorkUnitReport`) and `children` (an array of `DaemonStrategyReport`).
- **kind-constants**: `DaemonStrategyReport` MUST expose the static constants `timingKind` equal to `"timing"`, `eventKind` equal to `"event"` and `compositeKind` equal to `"composite"`, which are the kinds DaemonKit's `TimingStrategy`, `EventStrategy` and `CompositeStrategy` report.
- **kind-open**: `DaemonStrategyReport.kind` MUST accept any String value, because a daemon may report its own kind; a consumer SHOULD treat an unknown kind as opaque.
- **children-recursive**: `DaemonStrategyReport.children` MUST hold the child strategies of a composite and MUST be empty for a leaf strategy.
- **workunit-fields**: `DaemonWorkUnitReport` MUST carry `name` (String), `state` (a `State`), `nextActivation` (optional Date), `consecutiveFailures` (Int), `isBlocklisted` (Bool) and `lastMessage` (optional String). `nextActivation` and `lastMessage` are the optional fields: one that does not apply to a work unit MUST be `nil`.
- **workunit-state-values**: `DaemonWorkUnitReport.State` MUST be a String-backed enum with exactly the raw values `idle`, `running`, `disabled` and `blocklisted`.
- **workunit-memberwise-defaults**: The `DaemonWorkUnitReport` initializer MUST default `nextActivation` to `nil`, `consecutiveFailures` to `0`, `isBlocklisted` to `false` and `lastMessage` to `nil`.
- **strategy-memberwise-default**: The `DaemonStrategyReport` initializer MUST default `children` to an empty array.

**Decoding**

- **children-optional-on-wire**: Decoding a `DaemonStrategyReport` MUST treat a missing `children` key as an empty array, so a leaf strategy may omit it.
- **strategy-required-keys**: Decoding a `DaemonStrategyReport` MUST fail when `name`, `kind` or `workUnits` is missing.
- **workunit-required-keys**: Decoding a `DaemonWorkUnitReport` MUST fail when `name`, `state`, `consecutiveFailures` or `isBlocklisted` is missing; the initializer defaults do not apply to decoding.
- **workunit-optional-keys**: Decoding a `DaemonWorkUnitReport` MUST accept a missing or null `nextActivation` and a missing or null `lastMessage` as `nil`.
- **unknown-state-fails**: Decoding MUST fail for a work unit whose `state` is not one of the four `State` raw values, and because the enum has no fallback case, that failure fails the whole report.
- **decode-iso8601**: `DaemonHealthReport.decode(_:)` MUST decode dates with the ISO-8601 strategy, which is what DaemonKit encodes.
- **decode-nil-on-mismatch**: `DaemonHealthReport.decode(_:)` MUST return `nil` for any body it cannot decode, including a body in some other schema, because a daemon may answer `/health` in its own shape and still be up.
- **decode-no-error-detail**: `DaemonHealthReport.decode(_:)` MUST NOT surface the decoding error; the underlying failure is discarded and the caller receives only `nil`.

**Tree search**

- **first-of-kind-self**: `DaemonStrategyReport.first(ofKind:)` MUST return the receiver when the receiver's `kind` equals the argument.
- **first-of-kind-depth-first**: `DaemonStrategyReport.first(ofKind:)` MUST search `children` in order, depth first, and MUST return the first match found.
- **first-of-kind-none**: `DaemonStrategyReport.first(ofKind:)` MUST return `nil` when no strategy in the tree has the requested kind.

**Probe**

- **probe-url**: `DaemonHealthProbe.http(baseURL:timeout:)` MUST build the probe URL by appending the path component `health` to `baseURL` parsed as a URL. A trailing slash on `baseURL` MUST NOT produce a double slash, and a path on `baseURL` MUST be kept: `http://h:9000/` gives `http://h:9000/health` and `http://h/api` gives `http://h/api/health`.
- **probe-request**: Each invocation of the returned closure MUST issue one GET request that gives up when no data has been received for `timeout` seconds. The timeout is an idle timeout: a server that keeps sending bytes slowly MUST NOT trip it, and the total duration of the request is not bounded.
- **probe-default-timeout**: The `timeout` parameter MUST default to 2 seconds.
- **probe-200-only**: The returned closure MUST return the response body only when the HTTP status code is exactly 200.
- **probe-nil-on-failure**: The returned closure MUST return `nil` for any other status code, for a transport error and for an idle timeout.
- **probe-nil-on-bad-url**: The returned closure MUST return `nil`, without making a request, when `baseURL` cannot be parsed as a URL.
- **probe-non-http-response**: The returned closure MUST return `nil` when the response is not an `HTTPURLResponse`.
- **probe-body-raw**: The returned closure MUST return the body bytes undecoded; decoding is a separate call to `DaemonHealthReport.decode(_:)`.
- **probe-ephemeral-session**: The probe MUST use one ephemeral URL session, created when the probe is built and reused by every invocation of the returned closure, so that no cache, cookies or credentials persist to disk.
- **probe-sendable-async**: The returned closure MUST be `@Sendable` and `async`, so a caller may invoke it from any task.
- **probe-no-retry**: The probe MUST NOT retry; each invocation makes exactly one attempt, and the polling cadence belongs to the caller.

