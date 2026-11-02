from enum import StrEnum


class PutAccountMfaPreferenceResponse200PreferredMethod(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
