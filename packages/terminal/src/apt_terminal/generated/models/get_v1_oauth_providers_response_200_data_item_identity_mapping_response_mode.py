from enum import StrEnum


class GetV1OauthProvidersResponse200DataItemIdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
