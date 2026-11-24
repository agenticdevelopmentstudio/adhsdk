from enum import StrEnum


class GetV1AccountMfaResponse200PreferredMethodType1(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
