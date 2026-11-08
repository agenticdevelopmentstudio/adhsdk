from enum import StrEnum


class ProjectTemplateAuthorKind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
