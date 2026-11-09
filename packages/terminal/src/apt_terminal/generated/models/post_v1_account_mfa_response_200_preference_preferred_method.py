from enum import StrEnum


class PostV1AccountMfaResponse200PreferencePreferredMethod(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
