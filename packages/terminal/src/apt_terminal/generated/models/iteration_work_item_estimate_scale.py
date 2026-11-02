from enum import StrEnum


class IterationWorkItemEstimateScale(StrEnum):
    EXPONENTIAL = "exponential"
    FIBONACCI = "fibonacci"
    LINEAR = "linear"
    NONE = "none"
    POINTS = "points"
    TSHIRT = "tshirt"

    def __str__(self) -> str:
        return str(self.value)
