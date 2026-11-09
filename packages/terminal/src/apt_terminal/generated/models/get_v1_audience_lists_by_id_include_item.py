from enum import StrEnum


class GetV1AudienceListsByIdIncludeItem(StrEnum):
    STATS = "stats"

    def __str__(self) -> str:
        return str(self.value)
