from enum import StrEnum


class RegistryPersonaMayActKindsItem(StrEnum):
    ORG = "org"
    SELF = "self"
    TEAM = "team"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
