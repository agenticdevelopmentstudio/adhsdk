from enum import StrEnum


class CatalogFeatureSubscriptionTier(StrEnum):
    ENTERPRISE = "Enterprise"
    FREE = "Free"
    PRO = "Pro"
    TEAM = "Team"

    def __str__(self) -> str:
        return str(self.value)
