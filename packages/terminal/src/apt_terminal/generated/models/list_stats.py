from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ListStats")


@_attrs_define
class ListStats:
    """
    Attributes:
        subscribed (int): subscribed AND currently mailable
        unsubscribed (int):
        suppressed (int): subscribed but NOT mailable (deliveryStatus != 'ok' — bounced/complained/suppressed)
        total (int):
    """

    subscribed: int
    unsubscribed: int
    suppressed: int
    total: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subscribed = self.subscribed

        unsubscribed = self.unsubscribed

        suppressed = self.suppressed

        total = self.total

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subscribed": subscribed,
                "unsubscribed": unsubscribed,
                "suppressed": suppressed,
                "total": total,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subscribed = d.pop("subscribed")

        unsubscribed = d.pop("unsubscribed")

        suppressed = d.pop("suppressed")

        total = d.pop("total")

        list_stats = cls(
            subscribed=subscribed,
            unsubscribed=unsubscribed,
            suppressed=suppressed,
            total=total,
        )

        list_stats.additional_properties = d
        return list_stats

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
