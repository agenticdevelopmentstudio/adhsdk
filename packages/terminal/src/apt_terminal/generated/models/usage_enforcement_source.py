from enum import StrEnum


class UsageEnforcementSource(StrEnum):
    ENVIRONMENT = "environment"
    FLAG = "flag"

    def __str__(self) -> str:
        return str(self.value)
