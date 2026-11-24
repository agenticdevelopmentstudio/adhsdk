from enum import StrEnum


class GetV1EcosystemsByIdFeaturesIncludeItem(StrEnum):
    AVAILABILITY = "availability"

    def __str__(self) -> str:
        return str(self.value)
