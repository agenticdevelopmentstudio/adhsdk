from enum import StrEnum


class IntegrationProviderAuthMethod(StrEnum):
    API_KEY = "api_key"
    APP_PASSWORD = "app_password"
    GITHUB_APP = "github_app"
    OAUTH = "oauth"
    OAUTH_INSTANCE = "oauth_instance"
    PLAID_LINK = "plaid_link"

    def __str__(self) -> str:
        return str(self.value)
