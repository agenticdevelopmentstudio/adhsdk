from enum import StrEnum


class GetShiprReposIdPlatformsResponse200PlatformsItemKind(StrEnum):
    VERCEL = "vercel"

    def __str__(self) -> str:
        return str(self.value)
