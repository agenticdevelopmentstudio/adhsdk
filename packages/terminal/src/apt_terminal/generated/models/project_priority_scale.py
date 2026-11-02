from enum import StrEnum


class ProjectPriorityScale(StrEnum):
    NONE = "none"
    STANDARD = "standard"

    def __str__(self) -> str:
        return str(self.value)
