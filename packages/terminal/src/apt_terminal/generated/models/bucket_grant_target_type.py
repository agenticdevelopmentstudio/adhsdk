from enum import StrEnum


class BucketGrantTargetType(StrEnum):
    BUCKET = "bucket"
    BUCKET_TYPE = "bucket_type"
    ROW = "row"

    def __str__(self) -> str:
        return str(self.value)
