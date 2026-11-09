from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.usage_insight_run_rate_by_category_item import UsageInsightRunRateByCategoryItem


T = TypeVar("T", bound="UsageInsightRunRate")


@_attrs_define
class UsageInsightRunRate:
    """
    Attributes:
        month (str): YYYY-MM
        elapsed_days (int): Complete days: through yesterday (UTC) for the current month
        days_in_month (int):
        direct_to_date_micros (int | None): Direct cost over the elapsed days; null ⇒ every part of it is unpriced.
            Unpriced items add 0 to a priced total, so `unpricedItems` > 0 ⇒ a floor
        fixed_month_micros (int): The month's fixed cost, prorated by day
        projected_month_micros (int): direct to date (null ⇒ 0) ÷ elapsed days × days in month + fixed
        unpriced_items (int): Items with unpriced lines; > 0 ⇒ the direct figures are a floor
        by_category (list[UsageInsightRunRateByCategoryItem]):
    """

    month: str
    elapsed_days: int
    days_in_month: int
    direct_to_date_micros: int | None
    fixed_month_micros: int
    projected_month_micros: int
    unpriced_items: int
    by_category: list[UsageInsightRunRateByCategoryItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        month = self.month

        elapsed_days = self.elapsed_days

        days_in_month = self.days_in_month

        direct_to_date_micros: int | None
        direct_to_date_micros = self.direct_to_date_micros

        fixed_month_micros = self.fixed_month_micros

        projected_month_micros = self.projected_month_micros

        unpriced_items = self.unpriced_items

        by_category = []
        for by_category_item_data in self.by_category:
            by_category_item = by_category_item_data.to_dict()
            by_category.append(by_category_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "month": month,
                "elapsed_days": elapsed_days,
                "days_in_month": days_in_month,
                "direct_to_date_micros": direct_to_date_micros,
                "fixed_month_micros": fixed_month_micros,
                "projected_month_micros": projected_month_micros,
                "unpriced_items": unpriced_items,
                "by_category": by_category,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_run_rate_by_category_item import (
            UsageInsightRunRateByCategoryItem,
        )

        d = dict(src_dict)
        month = d.pop("month")

        elapsed_days = d.pop("elapsed_days")

        days_in_month = d.pop("days_in_month")

        def _parse_direct_to_date_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        direct_to_date_micros = _parse_direct_to_date_micros(d.pop("direct_to_date_micros"))

        fixed_month_micros = d.pop("fixed_month_micros")

        projected_month_micros = d.pop("projected_month_micros")

        unpriced_items = d.pop("unpriced_items")

        by_category = []
        _by_category = d.pop("by_category")
        for by_category_item_data in _by_category:
            by_category_item = UsageInsightRunRateByCategoryItem.from_dict(by_category_item_data)

            by_category.append(by_category_item)

        usage_insight_run_rate = cls(
            month=month,
            elapsed_days=elapsed_days,
            days_in_month=days_in_month,
            direct_to_date_micros=direct_to_date_micros,
            fixed_month_micros=fixed_month_micros,
            projected_month_micros=projected_month_micros,
            unpriced_items=unpriced_items,
            by_category=by_category,
        )

        usage_insight_run_rate.additional_properties = d
        return usage_insight_run_rate

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
