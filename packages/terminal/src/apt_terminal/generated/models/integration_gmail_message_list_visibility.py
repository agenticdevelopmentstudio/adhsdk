from enum import StrEnum


class IntegrationGmailMessageListVisibility(StrEnum):
    HIDE = "hide"
    SHOW = "show"

    def __str__(self) -> str:
        return str(self.value)
