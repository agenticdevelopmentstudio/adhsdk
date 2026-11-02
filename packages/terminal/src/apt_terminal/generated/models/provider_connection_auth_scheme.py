from enum import StrEnum


class ProviderConnectionAuthScheme(StrEnum):
    BEARER = "bearer"
    RAW = "raw"

    def __str__(self) -> str:
        return str(self.value)
