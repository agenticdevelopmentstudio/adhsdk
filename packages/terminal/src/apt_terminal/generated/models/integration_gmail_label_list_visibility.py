from enum import StrEnum


class IntegrationGmailLabelListVisibility(StrEnum):
    LABELHIDE = "labelHide"
    LABELSHOW = "labelShow"
    LABELSHOWIFUNREAD = "labelShowIfUnread"

    def __str__(self) -> str:
        return str(self.value)
