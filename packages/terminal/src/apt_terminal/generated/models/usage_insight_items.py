from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.usage_insight_item import UsageInsightItem


T = TypeVar("T", bound="UsageInsightItems")


@_attrs_define
class UsageInsightItems:
    """
    Attributes:
        from_ (datetime.date):
        to (datetime.date):
        items (list[UsageInsightItem]):
    """

    from_: datetime.date
    to: datetime.date
    items: list[UsageInsightItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from_ = self.from_.isoformat()

        to = self.to.isoformat()

        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "from": from_,
                "to": to,
                "items": items,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_item import UsageInsightItem

        d = dict(src_dict)
        from_ = datetime.date.fromisoformat(d.pop("from"))

        to = datetime.date.fromisoformat(d.pop("to"))

        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = UsageInsightItem.from_dict(items_item_data)

            items.append(items_item)

        usage_insight_items = cls(
            from_=from_,
            to=to,
            items=items,
        )

        usage_insight_items.additional_properties = d
        return usage_insight_items

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
