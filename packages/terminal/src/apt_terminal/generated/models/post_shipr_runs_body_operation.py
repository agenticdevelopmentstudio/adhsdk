from enum import StrEnum


class PostShiprRunsBodyOperation(StrEnum):
    DEPLOY = "deploy"
    PREPARE = "prepare"
    REGISTER = "register"
    STATUS = "status"
    UNREGISTER = "unregister"

    def __str__(self) -> str:
        return str(self.value)
