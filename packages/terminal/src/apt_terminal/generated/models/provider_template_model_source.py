from enum import StrEnum


class ProviderTemplateModelSource(StrEnum):
    CURATED = "curated"
    SYNCED = "synced"

    def __str__(self) -> str:
        return str(self.value)
