from enum import StrEnum


class ProjectTemplateKind(StrEnum):
    PROJECT = "project"
    WORK_ITEM = "work_item"

    def __str__(self) -> str:
        return str(self.value)
