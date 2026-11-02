from enum import StrEnum


class ProjectTemplateOwnerKind(StrEnum):
    CUSTOMER = "customer"
    ORGANIZATION = "organization"

    def __str__(self) -> str:
        return str(self.value)
