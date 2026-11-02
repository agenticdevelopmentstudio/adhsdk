from enum import StrEnum


class PatchRegistryRegistriesIdBodySubmissionPolicy(StrEnum):
    OPEN = "open"
    REVIEWED = "reviewed"

    def __str__(self) -> str:
        return str(self.value)
