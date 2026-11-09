from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.usage_llm_tokens import UsageLlmTokens


T = TypeVar("T", bound="UsageInsightBreakdownRow")


@_attrs_define
class UsageInsightBreakdownRow:
    """
    Attributes:
        key (UUID): The nil uuid is the unattributed row
        label (str): Name / handle; `Unattributed` for the nil key; the key when unresolved
        requests (float):
        server_ms (float):
        db_ms (float):
        llm_tokens (UsageLlmTokens):
        direct_micros (int | None): µUSD; null ⇒ every part of it is unpriced
        hosting_share_micros (int): Estimate: fixed cost × row (server + db ms) ÷ platform (server + db ms); each row is
            rounded separately, so rows may differ from fixedMicros by under 1 µUSD per row
        estimated_micros (int): Estimate: direct + hosting share
        unpriced_lines (int):
    """

    key: UUID
    label: str
    requests: float
    server_ms: float
    db_ms: float
    llm_tokens: UsageLlmTokens
    direct_micros: int | None
    hosting_share_micros: int
    estimated_micros: int
    unpriced_lines: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = str(self.key)

        label = self.label

        requests = self.requests

        server_ms = self.server_ms

        db_ms = self.db_ms

        llm_tokens = self.llm_tokens.to_dict()

        direct_micros: int | None
        direct_micros = self.direct_micros

        hosting_share_micros = self.hosting_share_micros

        estimated_micros = self.estimated_micros

        unpriced_lines = self.unpriced_lines

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "requests": requests,
                "server_ms": server_ms,
                "db_ms": db_ms,
                "llm_tokens": llm_tokens,
                "direct_micros": direct_micros,
                "hosting_share_micros": hosting_share_micros,
                "estimated_micros": estimated_micros,
                "unpriced_lines": unpriced_lines,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_llm_tokens import UsageLlmTokens

        d = dict(src_dict)
        key = UUID(d.pop("key"))

        label = d.pop("label")

        requests = d.pop("requests")

        server_ms = d.pop("server_ms")

        db_ms = d.pop("db_ms")

        llm_tokens = UsageLlmTokens.from_dict(d.pop("llm_tokens"))

        def _parse_direct_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        direct_micros = _parse_direct_micros(d.pop("direct_micros"))

        hosting_share_micros = d.pop("hosting_share_micros")

        estimated_micros = d.pop("estimated_micros")

        unpriced_lines = d.pop("unpriced_lines")

        usage_insight_breakdown_row = cls(
            key=key,
            label=label,
            requests=requests,
            server_ms=server_ms,
            db_ms=db_ms,
            llm_tokens=llm_tokens,
            direct_micros=direct_micros,
            hosting_share_micros=hosting_share_micros,
            estimated_micros=estimated_micros,
            unpriced_lines=unpriced_lines,
        )

        usage_insight_breakdown_row.additional_properties = d
        return usage_insight_breakdown_row

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
