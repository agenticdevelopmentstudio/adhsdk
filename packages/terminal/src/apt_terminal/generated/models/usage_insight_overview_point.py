from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.usage_llm_tokens import UsageLlmTokens


T = TypeVar("T", bound="UsageInsightOverviewPoint")


@_attrs_define
class UsageInsightOverviewPoint:
    """
    Attributes:
        start (datetime.date): First day of the bucket (a week starts Monday, UTC); may precede `from`
        requests (float):
        bytes_in (float):
        bytes_out (float):
        server_ms (float):
        db_ms (float):
        llm_tokens (UsageLlmTokens):
        embeddings (float): Embedding calls
        emails (float):
        sms_segments (float): SMS segments, plus one per send with no segment count
        storage_ops (float):
        direct_micros (int | None): µUSD; null ⇒ every part of it is unpriced
        unpriced_lines (int): Lines with no price or an incomplete one; > 0 ⇒ `directMicros` is a floor
    """

    start: datetime.date
    requests: float
    bytes_in: float
    bytes_out: float
    server_ms: float
    db_ms: float
    llm_tokens: UsageLlmTokens
    embeddings: float
    emails: float
    sms_segments: float
    storage_ops: float
    direct_micros: int | None
    unpriced_lines: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        start = self.start.isoformat()

        requests = self.requests

        bytes_in = self.bytes_in

        bytes_out = self.bytes_out

        server_ms = self.server_ms

        db_ms = self.db_ms

        llm_tokens = self.llm_tokens.to_dict()

        embeddings = self.embeddings

        emails = self.emails

        sms_segments = self.sms_segments

        storage_ops = self.storage_ops

        direct_micros: int | None
        direct_micros = self.direct_micros

        unpriced_lines = self.unpriced_lines

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "start": start,
                "requests": requests,
                "bytesIn": bytes_in,
                "bytesOut": bytes_out,
                "serverMs": server_ms,
                "dbMs": db_ms,
                "llmTokens": llm_tokens,
                "embeddings": embeddings,
                "emails": emails,
                "smsSegments": sms_segments,
                "storageOps": storage_ops,
                "directMicros": direct_micros,
                "unpricedLines": unpriced_lines,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_llm_tokens import UsageLlmTokens

        d = dict(src_dict)
        start = datetime.date.fromisoformat(d.pop("start"))

        requests = d.pop("requests")

        bytes_in = d.pop("bytesIn")

        bytes_out = d.pop("bytesOut")

        server_ms = d.pop("serverMs")

        db_ms = d.pop("dbMs")

        llm_tokens = UsageLlmTokens.from_dict(d.pop("llmTokens"))

        embeddings = d.pop("embeddings")

        emails = d.pop("emails")

        sms_segments = d.pop("smsSegments")

        storage_ops = d.pop("storageOps")

        def _parse_direct_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        direct_micros = _parse_direct_micros(d.pop("directMicros"))

        unpriced_lines = d.pop("unpricedLines")

        usage_insight_overview_point = cls(
            start=start,
            requests=requests,
            bytes_in=bytes_in,
            bytes_out=bytes_out,
            server_ms=server_ms,
            db_ms=db_ms,
            llm_tokens=llm_tokens,
            embeddings=embeddings,
            emails=emails,
            sms_segments=sms_segments,
            storage_ops=storage_ops,
            direct_micros=direct_micros,
            unpriced_lines=unpriced_lines,
        )

        usage_insight_overview_point.additional_properties = d
        return usage_insight_overview_point

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
