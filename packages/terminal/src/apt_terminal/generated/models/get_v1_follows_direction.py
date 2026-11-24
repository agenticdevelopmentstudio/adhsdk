from enum import StrEnum


class GetV1FollowsDirection(StrEnum):
    FOLLOWERS = "followers"
    FOLLOWING = "following"

    def __str__(self) -> str:
        return str(self.value)
