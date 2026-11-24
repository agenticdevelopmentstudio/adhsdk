from enum import StrEnum


class JobTemplateStatus(StrEnum):
    DRAFT = "draft"
    PUBLISHED = "published"
    RETIRED = "retired"

    def __str__(self) -> str:
        return str(self.value)
