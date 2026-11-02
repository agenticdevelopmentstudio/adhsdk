from enum import StrEnum


class IntegrationConnectApiKeyType(StrEnum):
    API_KEY = "api_key"

    def __str__(self) -> str:
        return str(self.value)
