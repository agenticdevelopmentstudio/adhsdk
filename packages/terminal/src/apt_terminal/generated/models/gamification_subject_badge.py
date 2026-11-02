from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GamificationSubjectBadge")


@_attrs_define
class GamificationSubjectBadge:
    """
    Attributes:
        id (str):
        badge_id (str):
        name (str):
        description (str):
        icon (str):
        awarded_at (str):
    """

    id: str
    badge_id: str
    name: str
    description: str
    icon: str
    awarded_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        badge_id = self.badge_id

        name = self.name

        description = self.description

        icon = self.icon

        awarded_at = self.awarded_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "badgeId": badge_id,
                "name": name,
                "description": description,
                "icon": icon,
                "awardedAt": awarded_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        badge_id = d.pop("badgeId")

        name = d.pop("name")

        description = d.pop("description")

        icon = d.pop("icon")

        awarded_at = d.pop("awardedAt")

        gamification_subject_badge = cls(
            id=id,
            badge_id=badge_id,
            name=name,
            description=description,
            icon=icon,
            awarded_at=awarded_at,
        )

        gamification_subject_badge.additional_properties = d
        return gamification_subject_badge

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
