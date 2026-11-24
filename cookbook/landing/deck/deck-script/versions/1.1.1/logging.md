
Not applicable: DeckScript does not emit log messages. It performs silent initialization; the one failure mode it anticipates — no viewport meta tag present when `restoreZoomOffIos` runs — is handled with a `load`-event retry and no reporting.

