from enum import StrEnum


class PatchProjectProjectsIdStatusesStatusIdBodyCategory(StrEnum):
    BACKLOG = "backlog"
    CANCELED = "canceled"
    DONE = "done"
    IN_PROGRESS = "in_progress"
    TODO = "todo"

    def __str__(self) -> str:
        return str(self.value)
