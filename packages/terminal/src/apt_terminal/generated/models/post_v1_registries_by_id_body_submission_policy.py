from enum import StrEnum


class PostV1RegistriesByIdBodySubmissionPolicy(StrEnum):
    OPEN = "open"
    REVIEWED = "reviewed"

    def __str__(self) -> str:
        return str(self.value)
