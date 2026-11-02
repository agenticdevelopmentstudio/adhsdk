from enum import StrEnum


class WorkItemFieldValueType(StrEnum):
    CHECKBOX = "checkbox"
    DATE = "date"
    NUMBER = "number"
    SELECT = "select"
    TEXT = "text"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
