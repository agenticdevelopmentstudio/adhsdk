from enum import StrEnum


class PostV1ProjectsByIdStatusUpdatesBodyHealth(StrEnum):
    AT_RISK = "at_risk"
    OFF_TRACK = "off_track"
    ON_TRACK = "on_track"

    def __str__(self) -> str:
        return str(self.value)
