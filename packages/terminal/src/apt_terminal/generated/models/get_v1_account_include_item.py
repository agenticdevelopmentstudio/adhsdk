from enum import StrEnum


class GetV1AccountIncludeItem(StrEnum):
    APPEARANCE = "appearance"
    COMMUNICATION_SETTINGS = "communication_settings"
    PRIVACY = "privacy"
    WORKSPACE_PREFS = "workspace_prefs"

    def __str__(self) -> str:
        return str(self.value)
