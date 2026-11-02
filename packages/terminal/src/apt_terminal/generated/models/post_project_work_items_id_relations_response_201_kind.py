from enum import StrEnum


class PostProjectWorkItemsIdRelationsResponse201Kind(StrEnum):
    DEPENDS_ON = "depends_on"
    DUPLICATES = "duplicates"
    RELATES_TO = "relates_to"

    def __str__(self) -> str:
        return str(self.value)
