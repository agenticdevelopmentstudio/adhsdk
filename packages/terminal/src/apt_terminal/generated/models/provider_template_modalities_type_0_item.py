from enum import StrEnum


class ProviderTemplateModalitiesType0Item(StrEnum):
    CHAT = "chat"
    IMAGE = "image"
    VIDEO = "video"

    def __str__(self) -> str:
        return str(self.value)
