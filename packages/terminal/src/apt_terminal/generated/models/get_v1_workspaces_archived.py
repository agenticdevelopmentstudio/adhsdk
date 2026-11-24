from enum import StrEnum


class GetV1WorkspacesArchived(StrEnum):
    TRUE = "true"

    def __str__(self) -> str:
        return str(self.value)
