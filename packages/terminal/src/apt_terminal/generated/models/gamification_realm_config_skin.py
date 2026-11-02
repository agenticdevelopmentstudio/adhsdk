from enum import StrEnum


class GamificationRealmConfigSkin(StrEnum):
    PLAIN = "plain"
    RPG = "rpg"

    def __str__(self) -> str:
        return str(self.value)
