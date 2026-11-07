from enum import StrEnum


class PostOauthProvidersResponse201IdentityMappingResponseMode(StrEnum):
    FORM_POST = "form_post"

    def __str__(self) -> str:
        return str(self.value)
