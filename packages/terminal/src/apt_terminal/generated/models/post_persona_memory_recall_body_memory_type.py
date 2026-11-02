from enum import StrEnum


class PostPersonaMemoryRecallBodyMemoryType(StrEnum):
    FEEDBACK = "feedback"
    PROJECT = "project"
    REFERENCE = "reference"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
