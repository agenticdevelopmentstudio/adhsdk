from enum import StrEnum


class JobInstancePatchOptionsOnError(StrEnum):
    CONTINUE = "continue"
    FAIL = "fail"

    def __str__(self) -> str:
        return str(self.value)
