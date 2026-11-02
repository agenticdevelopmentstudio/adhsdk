from enum import StrEnum


class PostRegistryRegistriesIdFieldDefsBodyShowIfType0Op(StrEnum):
    CONTAINS = "contains"
    EQ = "eq"
    FALSY = "falsy"
    IN = "in"
    NE = "ne"
    TRUTHY = "truthy"

    def __str__(self) -> str:
        return str(self.value)
