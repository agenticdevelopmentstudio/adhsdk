from enum import StrEnum


class PostV1AuthSessionsBodyMethod(StrEnum):
    MFA_PASSKEY = "mfa_passkey"
    PASSKEY = "passkey"
    PASSWORD = "password"
    RECOVERY = "recovery"
    SMS = "sms"
    TOTP = "totp"

    def __str__(self) -> str:
        return str(self.value)
