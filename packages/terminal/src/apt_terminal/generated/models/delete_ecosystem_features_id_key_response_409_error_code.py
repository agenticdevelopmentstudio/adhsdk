from enum import StrEnum


class DeleteEcosystemFeaturesIdKeyResponse409ErrorCode(StrEnum):
    FEATURE_REQUIRED = "feature_required"

    def __str__(self) -> str:
        return str(self.value)
