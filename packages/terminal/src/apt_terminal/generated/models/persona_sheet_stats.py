from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaSheetStats")


@_attrs_define
class PersonaSheetStats:
    """
    Attributes:
        adventures (int):
        allies (int):
        turns (int):
        tokens_out (int):
        avg_latency_ms (int | None):
        days_active (int):
    """

    adventures: int
    allies: int
    turns: int
    tokens_out: int
    avg_latency_ms: int | None
    days_active: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        adventures = self.adventures

        allies = self.allies

        turns = self.turns

        tokens_out = self.tokens_out

        avg_latency_ms: int | None
        avg_latency_ms = self.avg_latency_ms

        days_active = self.days_active

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "adventures": adventures,
                "allies": allies,
                "turns": turns,
                "tokensOut": tokens_out,
                "avgLatencyMs": avg_latency_ms,
                "daysActive": days_active,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        adventures = d.pop("adventures")

        allies = d.pop("allies")

        turns = d.pop("turns")

        tokens_out = d.pop("tokensOut")

        def _parse_avg_latency_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        avg_latency_ms = _parse_avg_latency_ms(d.pop("avgLatencyMs"))

        days_active = d.pop("daysActive")

        persona_sheet_stats = cls(
            adventures=adventures,
            allies=allies,
            turns=turns,
            tokens_out=tokens_out,
            avg_latency_ms=avg_latency_ms,
            days_active=days_active,
        )

        persona_sheet_stats.additional_properties = d
        return persona_sheet_stats

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
