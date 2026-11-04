from enum import StrEnum


class ProvisionedFeatureState(StrEnum):
    ACTIVE = "active"
    PROVISIONING = "provisioning"
    REMOVED = "removed"

    def __str__(self) -> str:
        return str(self.value)
