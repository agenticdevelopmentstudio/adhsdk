
Four `Codable` value types carry the daemon's two preference groups across the wire. `OversightPreferenceRequest` and `OversightPreferenceResponse` are the body and reply of `POST /preferences/oversight` and the reply of `GET /preferences/oversight`. `SummaryPreferenceRequest` and `SummaryPreferenceResponse` are the body and reply of `POST /preferences/summaries` and the reply of `GET /preferences/summaries`.

A request is a partial update: every field is optional, and an omitted field leaves the daemon's stored value alone (the snapshot push always sends all of them). A response is the full state the daemon runs with. They are encoded and decoded in the `StenographerWire` spelling (snake_case keys), so Swift's `maxWords` travels as `max_words`.

