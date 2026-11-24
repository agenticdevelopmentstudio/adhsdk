from enum import StrEnum


class GetV1ProjectsByIdIncludeItem(StrEnum):
    ATTACHABLE = "attachable"
    LABELS = "labels"

    def __str__(self) -> str:
        return str(self.value)
