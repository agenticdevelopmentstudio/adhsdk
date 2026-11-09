from enum import StrEnum


class GetV1ProviderTemplatesIncludeItem(StrEnum):
    SYNC_STATUS = "sync_status"

    def __str__(self) -> str:
        return str(self.value)
