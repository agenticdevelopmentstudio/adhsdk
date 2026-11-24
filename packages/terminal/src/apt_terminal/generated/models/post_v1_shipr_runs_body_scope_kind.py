from enum import StrEnum


class PostV1ShiprRunsBodyScopeKind(StrEnum):
    ALL = "all"
    DEPLOY_REPO = "deploy_repo"
    DEV_REPO = "dev_repo"
    GROUP = "group"

    def __str__(self) -> str:
        return str(self.value)
