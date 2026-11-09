from enum import StrEnum


class PostV1CustomerSessionsBodyMethod(StrEnum):
    PASSWORD = "password"
    RECOVERY = "recovery"
    SMS = "sms"
    TOTP = "totp"

    def __str__(self) -> str:
        return str(self.value)
