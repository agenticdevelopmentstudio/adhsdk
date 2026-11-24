from enum import StrEnum


class JobInstanceCreateOptionsOnError(StrEnum):
    CONTINUE = "continue"
    FAIL = "fail"

    def __str__(self) -> str:
        return str(self.value)
