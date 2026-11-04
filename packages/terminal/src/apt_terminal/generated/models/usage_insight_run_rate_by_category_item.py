from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageInsightRunRateByCategoryItem")


@_attrs_define
class UsageInsightRunRateByCategoryItem:
    """
    Attributes:
        category (str):
        direct_micros (int | None): µUSD; null ⇒ every part of it is unpriced
    """

    category: str
    direct_micros: int | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        category = self.category

        direct_micros: int | None
        direct_micros = self.direct_micros

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "category": category,
                "directMicros": direct_micros,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = d.pop("category")

        def _parse_direct_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        direct_micros = _parse_direct_micros(d.pop("directMicros"))

        usage_insight_run_rate_by_category_item = cls(
            category=category,
            direct_micros=direct_micros,
        )

        usage_insight_run_rate_by_category_item.additional_properties = d
        return usage_insight_run_rate_by_category_item

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
