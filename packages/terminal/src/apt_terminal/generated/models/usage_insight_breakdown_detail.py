from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_insight_breakdown_detail_by import UsageInsightBreakdownDetailBy

if TYPE_CHECKING:
    from ..models.usage_insight_breakdown_detail_daily_item import (
        UsageInsightBreakdownDetailDailyItem,
    )
    from ..models.usage_insight_item import UsageInsightItem


T = TypeVar("T", bound="UsageInsightBreakdownDetail")


@_attrs_define
class UsageInsightBreakdownDetail:
    """
    Attributes:
        by (UsageInsightBreakdownDetailBy):
        key (UUID):
        label (str):
        items (list[UsageInsightItem]):
        daily (list[UsageInsightBreakdownDetailDailyItem]): Every day of the range
    """

    by: UsageInsightBreakdownDetailBy
    key: UUID
    label: str
    items: list[UsageInsightItem]
    daily: list[UsageInsightBreakdownDetailDailyItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        by = self.by.value

        key = str(self.key)

        label = self.label

        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        daily = []
        for daily_item_data in self.daily:
            daily_item = daily_item_data.to_dict()
            daily.append(daily_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "by": by,
                "key": key,
                "label": label,
                "items": items,
                "daily": daily,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_breakdown_detail_daily_item import (
            UsageInsightBreakdownDetailDailyItem,
        )
        from ..models.usage_insight_item import UsageInsightItem

        d = dict(src_dict)
        by = UsageInsightBreakdownDetailBy(d.pop("by"))

        key = UUID(d.pop("key"))

        label = d.pop("label")

        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = UsageInsightItem.from_dict(items_item_data)

            items.append(items_item)

        daily = []
        _daily = d.pop("daily")
        for daily_item_data in _daily:
            daily_item = UsageInsightBreakdownDetailDailyItem.from_dict(daily_item_data)

            daily.append(daily_item)

        usage_insight_breakdown_detail = cls(
            by=by,
            key=key,
            label=label,
            items=items,
            daily=daily,
        )

        usage_insight_breakdown_detail.additional_properties = d
        return usage_insight_breakdown_detail

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
