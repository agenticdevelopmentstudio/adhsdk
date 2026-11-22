
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | `no usage readings in response` | `AccountQuotaReadingDTO.errorText` when neither window answered; a hardcoded English literal |
| (none) | `fable quota`, `spend`, `7d quota`, `5h quota` | Row labels used as wire markers and shown as row text; hardcoded English |

The display strings in the usage rows (`pctText`, `secondaryText`, `tokensText` and the rest) are formatted by the daemon and carried verbatim; the labels double as wire identifiers, so localizing them would change the wire contract.

