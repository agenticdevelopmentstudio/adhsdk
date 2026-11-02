from enum import StrEnum


class PublicPaperSearchHitKind(StrEnum):
    PAPER = "paper"
    RESEARCH = "research"

    def __str__(self) -> str:
        return str(self.value)
