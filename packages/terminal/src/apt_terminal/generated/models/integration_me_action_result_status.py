from enum import StrEnum


class IntegrationMeActionResultStatus(StrEnum):
    ERROR = "error"
    OK = "ok"

    def __str__(self) -> str:
        return str(self.value)
