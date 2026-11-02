from enum import StrEnum


class PersonaBootstrapBucketScope(StrEnum):
    GLOBAL = "global"

    def __str__(self) -> str:
        return str(self.value)
