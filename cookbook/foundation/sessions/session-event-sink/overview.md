
`SessionEventSink` is where a daemon publishes what it has ingested, so the code that ingests does not know whether subscribers are reached over SSE, XPC, both or neither. It has two operations: `broadcast(eventType:payload:sessionId:)` for one ingested hook event, and `broadcastSessionStatus(sessionId:status:)` for a liveness change that happened outside any hook event.

`SessionEventEncoding` is the one encoding of what a sink publishes. Ingestion encodes once and hands every sink the same bytes, so two daemons publish identical payloads whatever their transports. In the SDK's daemon code, `EventIngestor` calls `SessionEventEncoding.encode` on each ingested event and passes the bytes to `sink.broadcast`; `EventIngestor.broadcastSessionStatus` forwards status changes to the sink, and `LivenessService` reports its changes through an `onStatusChange` callback.

