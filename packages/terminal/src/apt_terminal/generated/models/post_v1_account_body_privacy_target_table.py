from enum import StrEnum


class PostV1AccountBodyPrivacyTargetTable(StrEnum):
    ADDRESSES = "addresses"
    AVATAR = "avatar"
    CONTACT_METHODS = "contact_methods"
    SOCIAL_LINKS = "social_links"

    def __str__(self) -> str:
        return str(self.value)
