from enum import StrEnum


class PostV1ProjectsByIdArtifactsBodyDirection(StrEnum):
    INGESTED = "ingested"
    PRODUCED = "produced"

    def __str__(self) -> str:
        return str(self.value)
