from enum import StrEnum


class GetContentMarkdownIdRouteAvailableRouteResponse200Reason(StrEnum):
    INVALID = "invalid"
    OK = "ok"
    RESERVED = "reserved"
    TAKEN = "taken"

    def __str__(self) -> str:
        return str(self.value)
