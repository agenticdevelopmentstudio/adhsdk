from enum import StrEnum


class GetV1IntegrationsConnectionsOwner(StrEnum):
    CUSTOMERS = "customers"

    def __str__(self) -> str:
        return str(self.value)
