from enum import StrEnum


class PostV1AccountLoginMethodsBodyType(StrEnum):
    PASSWORD = "password"
    PROVIDER = "provider"

    def __str__(self) -> str:
        return str(self.value)
