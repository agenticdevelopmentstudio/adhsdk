from enum import StrEnum


class PostV1ProviderTemplatesByIdBodyModalitiesType0Item(StrEnum):
    CHAT = "chat"
    IMAGE = "image"
    VIDEO = "video"

    def __str__(self) -> str:
        return str(self.value)
