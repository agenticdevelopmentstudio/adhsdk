from enum import StrEnum


class GetOauthSigninDiscoveryResponse200SignupMode(StrEnum):
    CLOSED = "closed"
    INVITE_ONLY = "invite_only"
    OPEN = "open"

    def __str__(self) -> str:
        return str(self.value)
