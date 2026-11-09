from enum import StrEnum


class PostV1AccessRolesByIdBodyDefaultFor(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"
    VALUE_0 = ""

    def __str__(self) -> str:
        return str(self.value)
