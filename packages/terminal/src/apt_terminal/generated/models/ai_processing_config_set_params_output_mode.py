from enum import StrEnum


class AiProcessingConfigSetParamsOutputMode(StrEnum):
    JSON = "json"
    SCHEMA = "schema"

    def __str__(self) -> str:
        return str(self.value)
