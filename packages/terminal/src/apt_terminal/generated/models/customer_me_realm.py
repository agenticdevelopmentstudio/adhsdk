from enum import StrEnum


class CustomerMeRealm(StrEnum):
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
