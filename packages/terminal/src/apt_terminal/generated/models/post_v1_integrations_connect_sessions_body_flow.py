from enum import StrEnum


class PostV1IntegrationsConnectSessionsBodyFlow(StrEnum):
    CONNECT = "connect"
    INSTALL = "install"
    LINK_TOKEN = "link_token"
    OAUTH = "oauth"

    def __str__(self) -> str:
        return str(self.value)
