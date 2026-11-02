from enum import StrEnum


class GetSearchDiscussionsType(StrEnum):
    POSTS = "posts"
    TOPICS = "topics"

    def __str__(self) -> str:
        return str(self.value)
