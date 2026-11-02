from enum import StrEnum


class PostProjectProjectsIdArtifactsBodyTargetKind(StrEnum):
    CONTENT_MARKDOWN = "content.markdown"
    CONTENT_URLS = "content.urls"

    def __str__(self) -> str:
        return str(self.value)
