from enum import StrEnum


class CatalogFeatureSetEntriesLimitsItemType(StrEnum):
    BYTES = "bytes"
    COUNT = "count"
    TIER = "tier"

    def __str__(self) -> str:
        return str(self.value)
