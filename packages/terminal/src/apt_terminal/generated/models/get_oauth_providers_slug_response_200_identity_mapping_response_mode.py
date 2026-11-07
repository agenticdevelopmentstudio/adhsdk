from enum import StrEnum


class GetOauthProvidersSlugResponse200IdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
