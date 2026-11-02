from enum import StrEnum


class ProjectIterationState(StrEnum):
    ACTIVE = "active"
    COMPLETED = "completed"
    UPCOMING = "upcoming"

    def __str__(self) -> str:
        return str(self.value)
