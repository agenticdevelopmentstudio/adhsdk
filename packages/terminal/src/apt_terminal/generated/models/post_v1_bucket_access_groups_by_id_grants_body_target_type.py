from enum import StrEnum


class PostV1BucketAccessGroupsByIdGrantsBodyTargetType(StrEnum):
    BUCKET = "bucket"
    BUCKET_TYPE = "bucket_type"

    def __str__(self) -> str:
        return str(self.value)
