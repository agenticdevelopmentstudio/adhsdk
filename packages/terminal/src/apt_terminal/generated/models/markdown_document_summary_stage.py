from enum import StrEnum


class MarkdownDocumentSummaryStage(StrEnum):
    DRAFT = "draft"
    FINAL = "final"

    def __str__(self) -> str:
        return str(self.value)
