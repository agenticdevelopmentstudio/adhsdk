from enum import StrEnum


class PatchOauthProvidersSlugResponse200IdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
