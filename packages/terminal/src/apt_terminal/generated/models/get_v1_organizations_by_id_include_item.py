from enum import StrEnum


class GetV1OrganizationsByIdIncludeItem(StrEnum):
    SHEET = "sheet"

    def __str__(self) -> str:
        return str(self.value)
