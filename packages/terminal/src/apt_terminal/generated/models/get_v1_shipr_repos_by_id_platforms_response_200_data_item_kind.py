from enum import StrEnum


class GetV1ShiprReposByIdPlatformsResponse200DataItemKind(StrEnum):
    VERCEL = "vercel"

    def __str__(self) -> str:
        return str(self.value)
