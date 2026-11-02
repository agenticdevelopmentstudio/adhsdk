from enum import StrEnum


class PutAccountMfaPreferenceBodyMethod(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
