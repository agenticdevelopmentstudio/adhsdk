from enum import StrEnum


class OrgSheetSubjectType(StrEnum):
    ORG = "org"

    def __str__(self) -> str:
        return str(self.value)
