from enum import StrEnum


class GetAccountMfaPreferenceResponse200PreferredMethodType3Type1(StrEnum):
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
