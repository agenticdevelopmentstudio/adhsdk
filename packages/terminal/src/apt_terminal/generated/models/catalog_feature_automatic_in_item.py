from enum import StrEnum


class CatalogFeatureAutomaticInItem(StrEnum):
    CONTAINER = "container"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    PERSONAL = "personal"
    PRODUCT = "product"
    WORKSPACE = "workspace"

    def __str__(self) -> str:
        return str(self.value)
