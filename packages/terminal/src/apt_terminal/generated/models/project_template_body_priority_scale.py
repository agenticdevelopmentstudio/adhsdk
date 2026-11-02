from enum import StrEnum


class ProjectTemplateBodyPriorityScale(StrEnum):
    NONE = "none"
    STANDARD = "standard"

    def __str__(self) -> str:
        return str(self.value)
