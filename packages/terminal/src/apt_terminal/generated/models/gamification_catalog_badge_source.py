from enum import StrEnum


class GamificationCatalogBadgeSource(StrEnum):
    DEFAULT = "default"
    REALM = "realm"

    def __str__(self) -> str:
        return str(self.value)
