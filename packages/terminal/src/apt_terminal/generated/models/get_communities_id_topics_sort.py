from enum import StrEnum


class GetCommunitiesIdTopicsSort(StrEnum):
    POPULAR = "popular"
    RECENT = "recent"
    TRENDING = "trending"

    def __str__(self) -> str:
        return str(self.value)
