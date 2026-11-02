from enum import StrEnum


class UsageSummaryRowScope(StrEnum):
    APPLICATION = "application"
    ECOSYSTEM = "ecosystem"
    PERSONA = "persona"
    TOKEN = "token"
    USER = "user"
    VISITOR = "visitor"
    VISITOR_GLOBAL = "visitor_global"

    def __str__(self) -> str:
        return str(self.value)
