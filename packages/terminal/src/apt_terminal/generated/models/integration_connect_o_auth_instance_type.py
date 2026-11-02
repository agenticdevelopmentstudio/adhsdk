from enum import StrEnum


class IntegrationConnectOAuthInstanceType(StrEnum):
    OAUTH_INSTANCE = "oauth_instance"

    def __str__(self) -> str:
        return str(self.value)
