from enum import StrEnum


class PostV1NotificationPreferencesBodyType1PreferencesItemCategory(StrEnum):
    ACCOUNT = "account"
    ADMIN_ANNOUNCEMENT = "admin_announcement"
    COMMUNITY_MENTION = "community_mention"
    COMMUNITY_REPLY = "community_reply"
    DIRECT_MESSAGE = "direct_message"
    PROJECT_ASSIGNED = "project_assigned"
    PROJECT_COMMENT = "project_comment"
    PROJECT_DUE = "project_due"
    PROJECT_MENTION = "project_mention"
    PROJECT_STATUS = "project_status"

    def __str__(self) -> str:
        return str(self.value)
