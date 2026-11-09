from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageInsightRate")


@_attrs_define
class UsageInsightRate:
    """
    Attributes:
        category (str):
        provider (str):
        sku (str):
        quantity_key (str): The `quantities` key the rate prices
        micros_per_unit (str): Decimal µUSD per unit (numeric text; may be a fraction of a µUSD)
        effective_from (datetime.date):
    """

    category: str
    provider: str
    sku: str
    quantity_key: str
    micros_per_unit: str
    effective_from: datetime.date
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        category = self.category

        provider = self.provider

        sku = self.sku

        quantity_key = self.quantity_key

        micros_per_unit = self.micros_per_unit

        effective_from = self.effective_from.isoformat()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantity_key": quantity_key,
                "micros_per_unit": micros_per_unit,
                "effective_from": effective_from,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = d.pop("category")

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantity_key = d.pop("quantity_key")

        micros_per_unit = d.pop("micros_per_unit")

        effective_from = datetime.date.fromisoformat(d.pop("effective_from"))

        usage_insight_rate = cls(
            category=category,
            provider=provider,
            sku=sku,
            quantity_key=quantity_key,
            micros_per_unit=micros_per_unit,
            effective_from=effective_from,
        )

        usage_insight_rate.additional_properties = d
        return usage_insight_rate

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
