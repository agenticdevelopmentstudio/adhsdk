from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_insight_item_source import UsageInsightItemSource

if TYPE_CHECKING:
    from ..models.usage_insight_item_quantities import UsageInsightItemQuantities
    from ..models.usage_insight_rate import UsageInsightRate


T = TypeVar("T", bound="UsageInsightItem")


@_attrs_define
class UsageInsightItem:
    """
    Attributes:
        category (str):
        provider (str):
        sku (str):
        quantities (UsageInsightItemQuantities): Key-wise sums of the quantities (requests, input_tokens, minutes, …)
        captured_micros (int): Sum of the prices captured on the platform-paid lines
        cost_micros (int | None): Priced per (item, day): a rate in effect overrides the captured price. null ⇒
            unpriced; a non-zero `unpricedLines` ⇒ a floor
        source (UsageInsightItemSource): How the range was priced; `mixed` when days differ (a rate starting mid-range),
            `customer_key` when none of it was platform-paid
        unpriced_lines (int):
        lines (int):
        rates (list[UsageInsightRate]): The rates in effect on some day of the range
    """

    category: str
    provider: str
    sku: str
    quantities: UsageInsightItemQuantities
    captured_micros: int
    cost_micros: int | None
    source: UsageInsightItemSource
    unpriced_lines: int
    lines: int
    rates: list[UsageInsightRate]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        category = self.category

        provider = self.provider

        sku = self.sku

        quantities = self.quantities.to_dict()

        captured_micros = self.captured_micros

        cost_micros: int | None
        cost_micros = self.cost_micros

        source = self.source.value

        unpriced_lines = self.unpriced_lines

        lines = self.lines

        rates = []
        for rates_item_data in self.rates:
            rates_item = rates_item_data.to_dict()
            rates.append(rates_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantities": quantities,
                "captured_micros": captured_micros,
                "cost_micros": cost_micros,
                "source": source,
                "unpriced_lines": unpriced_lines,
                "lines": lines,
                "rates": rates,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_item_quantities import (
            UsageInsightItemQuantities,
        )
        from ..models.usage_insight_rate import UsageInsightRate

        d = dict(src_dict)
        category = d.pop("category")

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantities = UsageInsightItemQuantities.from_dict(d.pop("quantities"))

        captured_micros = d.pop("captured_micros")

        def _parse_cost_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        cost_micros = _parse_cost_micros(d.pop("cost_micros"))

        source = UsageInsightItemSource(d.pop("source"))

        unpriced_lines = d.pop("unpriced_lines")

        lines = d.pop("lines")

        rates = []
        _rates = d.pop("rates")
        for rates_item_data in _rates:
            rates_item = UsageInsightRate.from_dict(rates_item_data)

            rates.append(rates_item)

        usage_insight_item = cls(
            category=category,
            provider=provider,
            sku=sku,
            quantities=quantities,
            captured_micros=captured_micros,
            cost_micros=cost_micros,
            source=source,
            unpriced_lines=unpriced_lines,
            lines=lines,
            rates=rates,
        )

        usage_insight_item.additional_properties = d
        return usage_insight_item

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
