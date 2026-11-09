from enum import StrEnum


class PostV1ShiprRunsBodyEnvironmentsItem(StrEnum):
    PRODUCTION = "production"
    STAGING = "staging"
    TESTING = "testing"

    def __str__(self) -> str:
        return str(self.value)
