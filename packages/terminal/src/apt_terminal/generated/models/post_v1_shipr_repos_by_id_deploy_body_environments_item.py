from enum import StrEnum


class PostV1ShiprReposByIdDeployBodyEnvironmentsItem(StrEnum):
    PRODUCTION = "production"
    STAGING = "staging"
    TESTING = "testing"

    def __str__(self) -> str:
        return str(self.value)
