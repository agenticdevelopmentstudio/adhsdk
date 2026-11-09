from enum import StrEnum


class GetV1ProjectsByIdArtifactsDirection(StrEnum):
    INGESTED = "ingested"
    PRODUCED = "produced"

    def __str__(self) -> str:
        return str(self.value)
