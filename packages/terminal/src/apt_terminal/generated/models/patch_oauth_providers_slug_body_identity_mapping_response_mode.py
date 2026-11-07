from enum import StrEnum


class PatchOauthProvidersSlugBodyIdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
