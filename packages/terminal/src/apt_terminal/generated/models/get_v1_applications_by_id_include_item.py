from enum import StrEnum


class GetV1ApplicationsByIdIncludeItem(StrEnum):
    CLIENT_AUTH = "client_auth"
    SCHEMA_GRANTS = "schema_grants"

    def __str__(self) -> str:
        return str(self.value)
