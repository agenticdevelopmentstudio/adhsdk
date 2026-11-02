from enum import StrEnum


class UsageEnforcementUnknownPricePolicy(StrEnum):
    CEILING = "ceiling"
    FREE = "free"
    REFUSE = "refuse"

    def __str__(self) -> str:
        return str(self.value)
