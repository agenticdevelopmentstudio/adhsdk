from enum import StrEnum


class CatalogSyncOutcomeSource(StrEnum):
    ARENA = "arena"
    MODELSDEV = "modelsDev"
    OPENROUTER = "openrouter"

    def __str__(self) -> str:
        return str(self.value)
