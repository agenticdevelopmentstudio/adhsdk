from enum import StrEnum


class ProjectArtifactDirection(StrEnum):
    INGESTED = "ingested"
    PRODUCED = "produced"

    def __str__(self) -> str:
        return str(self.value)
