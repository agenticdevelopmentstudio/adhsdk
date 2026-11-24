from enum import StrEnum


class GetV1EcosystemsByIdIncludeItem(StrEnum):
    AUTH_SETTINGS = "auth_settings"
    CLIENT_AUTH = "client_auth"

    def __str__(self) -> str:
        return str(self.value)
