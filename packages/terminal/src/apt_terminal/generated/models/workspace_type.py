from enum import StrEnum


class WorkspaceType(StrEnum):
    INDIVIDUAL = "individual"
    ORGANIZATION = "organization"
    TEAM = "team"

    def __str__(self) -> str:
        return str(self.value)
