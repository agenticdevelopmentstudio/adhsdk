from enum import StrEnum


class UsageCostLineCategory(StrEnum):
    EMAIL = "email"
    EMBEDDING = "embedding"
    LLM = "llm"
    OUTBOUND_HTTP = "outbound_http"
    REALTIME = "realtime"
    SMS = "sms"
    STORAGE_OP = "storage_op"

    def __str__(self) -> str:
        return str(self.value)
