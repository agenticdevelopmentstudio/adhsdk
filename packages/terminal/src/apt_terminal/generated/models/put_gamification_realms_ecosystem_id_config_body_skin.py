from enum import StrEnum


class PutGamificationRealmsEcosystemIdConfigBodySkin(StrEnum):
    PLAIN = "plain"
    RPG = "rpg"

    def __str__(self) -> str:
        return str(self.value)
