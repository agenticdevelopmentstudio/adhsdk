from enum import StrEnum


class IntegrationConnectAppPasswordType(StrEnum):
    APP_PASSWORD = "app_password"

    def __str__(self) -> str:
        return str(self.value)
