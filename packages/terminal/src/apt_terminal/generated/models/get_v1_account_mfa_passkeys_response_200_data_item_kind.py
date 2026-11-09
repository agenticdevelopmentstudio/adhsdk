from enum import StrEnum


class GetV1AccountMfaPasskeysResponse200DataItemKind(StrEnum):
    PASSKEY = "passkey"
    SECURITY_KEY = "security_key"

    def __str__(self) -> str:
        return str(self.value)
