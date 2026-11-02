from enum import StrEnum


class GetAccountMfaResponse200PreferredMethodType2Type1(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
