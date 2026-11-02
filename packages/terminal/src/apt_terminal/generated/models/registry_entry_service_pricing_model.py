from enum import StrEnum


class RegistryEntryServicePricingModel(StrEnum):
    BARTER = "barter"
    FREE = "free"
    HOURLY = "hourly"
    PER_DELIVERABLE = "per_deliverable"
    PER_JOB = "per_job"
    SUBSCRIPTION = "subscription"

    def __str__(self) -> str:
        return str(self.value)
