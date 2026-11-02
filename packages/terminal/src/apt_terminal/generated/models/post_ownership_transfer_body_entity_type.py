from enum import StrEnum


class PostOwnershipTransferBodyEntityType(StrEnum):
    APPLICATION = "application"
    BUCKET = "bucket"
    ECOSYSTEM = "ecosystem"
    PERSONA = "persona"
    PROJECT = "project"
    SITE_GROUP = "site-group"

    def __str__(self) -> str:
        return str(self.value)
