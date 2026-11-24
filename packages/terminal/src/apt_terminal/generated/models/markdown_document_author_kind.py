from enum import StrEnum


class MarkdownDocumentAuthorKind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
