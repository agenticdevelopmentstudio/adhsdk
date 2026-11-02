from enum import StrEnum


class PostPersonaPersonasIdTokensBodySubjectKind(StrEnum):
    ORG = "org"
    SELF = "self"
    TEAM = "team"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
