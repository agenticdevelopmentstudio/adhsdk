from enum import StrEnum


class PostProjectProjectsIdWorkItemsIncludeUntriaged(StrEnum):
    TRUE = "true"

    def __str__(self) -> str:
        return str(self.value)
