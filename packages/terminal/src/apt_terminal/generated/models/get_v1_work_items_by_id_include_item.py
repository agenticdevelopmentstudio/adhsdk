from enum import StrEnum


class GetV1WorkItemsByIdIncludeItem(StrEnum):
    FIELDS = "fields"

    def __str__(self) -> str:
        return str(self.value)
