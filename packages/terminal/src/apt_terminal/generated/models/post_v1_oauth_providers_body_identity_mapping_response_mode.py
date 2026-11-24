from enum import StrEnum


class PostV1OauthProvidersBodyIdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
