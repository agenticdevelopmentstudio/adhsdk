from enum import StrEnum


class GetPublicCommunitiesIdTopicsSort(StrEnum):
    POPULAR = "popular"
    RECENT = "recent"
    TRENDING = "trending"

    def __str__(self) -> str:
        return str(self.value)
