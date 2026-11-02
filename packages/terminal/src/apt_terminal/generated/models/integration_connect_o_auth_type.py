from enum import StrEnum


class IntegrationConnectOAuthType(StrEnum):
    OAUTH = "oauth"

    def __str__(self) -> str:
        return str(self.value)
