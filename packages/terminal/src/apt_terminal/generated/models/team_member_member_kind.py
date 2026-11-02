from enum import StrEnum


class TeamMemberMemberKind(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
