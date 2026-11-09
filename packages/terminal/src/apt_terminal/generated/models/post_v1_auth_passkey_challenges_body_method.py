from enum import StrEnum


class PostV1AuthPasskeyChallengesBodyMethod(StrEnum):
    MFA_PASSKEY = "mfa_passkey"
    PASSKEY = "passkey"

    def __str__(self) -> str:
        return str(self.value)
