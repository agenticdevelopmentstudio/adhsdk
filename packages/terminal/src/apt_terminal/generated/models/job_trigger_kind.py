from enum import StrEnum


class JobTriggerKind(StrEnum):
    EVENT = "event"
    INBOUND = "inbound"
    SCHEDULE = "schedule"

    def __str__(self) -> str:
        return str(self.value)
