from enum import StrEnum


class PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBodyCredentialStyle(StrEnum):
    BASIC_AUTH = "basic_auth"
    FORM_BODY = "form_body"

    def __str__(self) -> str:
        return str(self.value)
