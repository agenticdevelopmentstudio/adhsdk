from enum import StrEnum


class IntegrationConnectPlaidLinkType(StrEnum):
    PLAID_LINK = "plaid_link"

    def __str__(self) -> str:
        return str(self.value)
