from enum import StrEnum


class GetV1ProviderTemplatesByIdIncludeItem(StrEnum):
    SYNC_KEYS = "sync_keys"

    def __str__(self) -> str:
        return str(self.value)
