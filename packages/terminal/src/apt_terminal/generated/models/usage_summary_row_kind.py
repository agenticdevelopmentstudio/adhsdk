from enum import StrEnum


class UsageSummaryRowKind(StrEnum):
    APPLICATION = "application"
    ECOSYSTEM = "ecosystem"
    MEMBER = "member"
    PERSONA = "persona"
    SELF = "self"
    TOKEN = "token"

    def __str__(self) -> str:
        return str(self.value)
