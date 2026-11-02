from enum import StrEnum


class GetOauthProvidersResponse200ItemAuthType(StrEnum):
    OAUTH2_ACCESS_TOKEN = "oauth2_access_token"
    OAUTH2_CODE = "oauth2_code"
    OIDC_ID_TOKEN = "oidc_id_token"

    def __str__(self) -> str:
        return str(self.value)
