from enum import StrEnum


class PostShiprReposIdPrepareBodyEnvironmentsItem(StrEnum):
    PRODUCTION = "production"
    STAGING = "staging"
    TESTING = "testing"

    def __str__(self) -> str:
        return str(self.value)
