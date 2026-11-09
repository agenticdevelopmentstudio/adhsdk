from enum import StrEnum


class GetV1TeamMembersIncludeItem(StrEnum):
    TOTAL_COUNT = "total_count"

    def __str__(self) -> str:
        return str(self.value)
