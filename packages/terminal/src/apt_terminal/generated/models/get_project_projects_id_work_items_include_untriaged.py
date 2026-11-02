from enum import StrEnum


class GetProjectProjectsIdWorkItemsIncludeUntriaged(StrEnum):
    TRUE = "true"

    def __str__(self) -> str:
        return str(self.value)
