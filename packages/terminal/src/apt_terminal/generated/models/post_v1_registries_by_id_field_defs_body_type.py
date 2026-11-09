from enum import StrEnum


class PostV1RegistriesByIdFieldDefsBodyType(StrEnum):
    ADDRESS = "address"
    BOOLEAN = "boolean"
    DATE = "date"
    EMAIL = "email"
    IMAGE = "image"
    MARKDOWN = "markdown"
    MULTI_SELECT = "multi_select"
    PHONE = "phone"
    SELECT = "select"
    TEXT = "text"
    TEXTAREA = "textarea"
    URL = "url"

    def __str__(self) -> str:
        return str(self.value)
