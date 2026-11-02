from enum import StrEnum


class IntegrationConnectGithubAppType(StrEnum):
    GITHUB_APP = "github_app"

    def __str__(self) -> str:
        return str(self.value)
