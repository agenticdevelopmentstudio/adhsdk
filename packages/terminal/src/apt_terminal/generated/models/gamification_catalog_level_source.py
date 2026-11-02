from enum import StrEnum


class GamificationCatalogLevelSource(StrEnum):
    DEFAULT = "default"
    REALM = "realm"

    def __str__(self) -> str:
        return str(self.value)
