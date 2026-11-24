from enum import StrEnum


class PostV1GamificationConfigBodySkin(StrEnum):
    PLAIN = "plain"
    RPG = "rpg"

    def __str__(self) -> str:
        return str(self.value)
