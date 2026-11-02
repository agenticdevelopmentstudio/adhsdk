from enum import StrEnum


class MfaChallengeMethodsItem(StrEnum):
    RECOVERY = "recovery"
    SMS = "sms"
    TOTP = "totp"
    WEBAUTHN = "webauthn"

    def __str__(self) -> str:
        return str(self.value)
