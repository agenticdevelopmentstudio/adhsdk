from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_insight_item import UsageInsightItem


T = TypeVar("T", bound="GetV1UsageInsightsItemsResponse200")


@_attrs_define
class GetV1UsageInsightsItemsResponse200:
    """
    Attributes:
        from_ (datetime.date):
        to (datetime.date):
        items (list[UsageInsightItem]):
        object_ (Literal['usage.insights.item'] | Unset):
    """

    from_: datetime.date
    to: datetime.date
    items: list[UsageInsightItem]
    object_: Literal["usage.insights.item"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from_ = self.from_.isoformat()

        to = self.to.isoformat()

        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "from": from_,
                "to": to,
                "items": items,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["usage.insights.item"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.insights.item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.insights.item', got '{object_}'")

        get_v1_usage_insights_items_response_200 = cls(
            from_=from_,
            to=to,
            items=items,
            object_=object_,
        )

        get_v1_usage_insights_items_response_200.additional_properties = d
        return get_v1_usage_insights_items_response_200

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
