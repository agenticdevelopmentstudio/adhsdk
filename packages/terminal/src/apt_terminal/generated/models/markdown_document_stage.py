from enum import StrEnum


class MarkdownDocumentStage(StrEnum):
    DRAFT = "draft"
    FINAL = "final"

    def __str__(self) -> str:
        return str(self.value)
