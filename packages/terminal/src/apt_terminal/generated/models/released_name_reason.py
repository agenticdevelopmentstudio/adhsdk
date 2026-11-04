from enum import StrEnum


class ReleasedNameReason(StrEnum):
    DELETED_ENTITY = "deleted-entity"
    ORPHAN = "orphan"
    RENAME_LEFTOVER = "rename-leftover"

    def __str__(self) -> str:
        return str(self.value)
