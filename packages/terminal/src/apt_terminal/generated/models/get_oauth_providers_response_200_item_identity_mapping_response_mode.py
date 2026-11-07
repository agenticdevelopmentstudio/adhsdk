from enum import StrEnum


class GetOauthProvidersResponse200ItemIdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
