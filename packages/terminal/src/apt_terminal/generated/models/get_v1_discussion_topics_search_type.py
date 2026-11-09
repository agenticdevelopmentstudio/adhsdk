from enum import StrEnum


class GetV1DiscussionTopicsSearchType(StrEnum):
    POSTS = "posts"
    TOPICS = "topics"

    def __str__(self) -> str:
        return str(self.value)
