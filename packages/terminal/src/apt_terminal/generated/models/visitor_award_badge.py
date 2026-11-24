from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="VisitorAwardBadge")


@_attrs_define
class VisitorAwardBadge:
    """
    Attributes:
        badge_id (str):
        name (str):
        icon (str):
        tier (str):
        description (str):
    """

    badge_id: str
    name: str
    icon: str
    tier: str
    description: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        badge_id = self.badge_id

        name = self.name

        icon = self.icon

        tier = self.tier

        description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "badge_id": badge_id,
                "name": name,
                "icon": icon,
                "tier": tier,
                "description": description,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        badge_id = d.pop("badge_id")

        name = d.pop("name")

        icon = d.pop("icon")

        tier = d.pop("tier")

        description = d.pop("description")

        visitor_award_badge = cls(
            badge_id=badge_id,
            name=name,
            icon=icon,
            tier=tier,
            description=description,
        )

        visitor_award_badge.additional_properties = d
        return visitor_award_badge

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
