from enum import StrEnum


class GetV1WorkItemsTriage(StrEnum):
    TRUE = "true"

    def __str__(self) -> str:
        return str(self.value)
