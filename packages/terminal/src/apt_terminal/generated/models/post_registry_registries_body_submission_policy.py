from enum import StrEnum


class PostRegistryRegistriesBodySubmissionPolicy(StrEnum):
    OPEN = "open"
    REVIEWED = "reviewed"

    def __str__(self) -> str:
        return str(self.value)
