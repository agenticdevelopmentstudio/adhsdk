from enum import StrEnum


class ApplicationClientAuthPlatform(StrEnum):
    NATIVE = "native"
    WEB = "web"

    def __str__(self) -> str:
        return str(self.value)
