from enum import StrEnum


class PutBucketAccessGroupsGroupIdGrantsBodyTargetType(StrEnum):
    BUCKET = "bucket"
    BUCKET_TYPE = "bucket_type"

    def __str__(self) -> str:
        return str(self.value)
