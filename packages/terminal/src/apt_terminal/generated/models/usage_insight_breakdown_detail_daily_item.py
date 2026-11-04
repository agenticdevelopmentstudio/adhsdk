from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageInsightBreakdownDetailDailyItem")


@_attrs_define
class UsageInsightBreakdownDetailDailyItem:
    """
    Attributes:
        day (datetime.date):
        direct_micros (int | None): µUSD; null ⇒ every part of it is unpriced
        unpriced_lines (int): Lines with no price or an incomplete one; > 0 ⇒ `directMicros` is a floor
        requests (float):
    """

    day: datetime.date
    direct_micros: int | None
    unpriced_lines: int
    requests: float
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        day = self.day.isoformat()

        direct_micros: int | None
        direct_micros = self.direct_micros

        unpriced_lines = self.unpriced_lines

        requests = self.requests

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "day": day,
                "directMicros": direct_micros,
                "unpricedLines": unpriced_lines,
                "requests": requests,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        day = datetime.date.fromisoformat(d.pop("day"))

        def _parse_direct_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        direct_micros = _parse_direct_micros(d.pop("directMicros"))

        unpriced_lines = d.pop("unpricedLines")

        requests = d.pop("requests")

        usage_insight_breakdown_detail_daily_item = cls(
            day=day,
            direct_micros=direct_micros,
            unpriced_lines=unpriced_lines,
            requests=requests,
        )

        usage_insight_breakdown_detail_daily_item.additional_properties = d
        return usage_insight_breakdown_detail_daily_item

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
