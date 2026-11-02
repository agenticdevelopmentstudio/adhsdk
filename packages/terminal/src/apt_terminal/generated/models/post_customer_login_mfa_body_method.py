from enum import StrEnum


class PostCustomerLoginMfaBodyMethod(StrEnum):
    RECOVERY = "recovery"
    SMS = "sms"
    TOTP = "totp"

    def __str__(self) -> str:
        return str(self.value)
