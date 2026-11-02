from enum import StrEnum


class PatchProjectProjectsIdBodyPriorityScale(StrEnum):
    NONE = "none"
    STANDARD = "standard"

    def __str__(self) -> str:
        return str(self.value)
