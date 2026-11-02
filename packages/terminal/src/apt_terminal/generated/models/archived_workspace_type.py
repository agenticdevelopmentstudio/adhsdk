from enum import StrEnum


class ArchivedWorkspaceType(StrEnum):
    ORGANIZATION = "organization"

    def __str__(self) -> str:
        return str(self.value)
