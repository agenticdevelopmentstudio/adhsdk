from enum import StrEnum


class SetGrantSource(StrEnum):
    DIRECT = "direct"
    OFFER = "offer"
    SIGNUP = "signup"

    def __str__(self) -> str:
        return str(self.value)
