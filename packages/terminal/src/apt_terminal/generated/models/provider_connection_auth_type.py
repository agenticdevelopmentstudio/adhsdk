from enum import StrEnum


class ProviderConnectionAuthType(StrEnum):
    BEARER = "bearer"
    HEADER = "header"
    OAUTH2 = "oauth2"
    SIGV4 = "sigv4"

    def __str__(self) -> str:
        return str(self.value)
