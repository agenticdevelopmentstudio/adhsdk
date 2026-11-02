from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="SubjectSheetBadgesItem")


@_attrs_define
class SubjectSheetBadgesItem:
    """
    Attributes:
        badge_id (str):
        name (str):
        description (str):
        icon (str):
        tier (str):
        badge_line (None | str):
        awarded_at (str):
        rarity_pct (float | None):
    """

    badge_id: str
    name: str
    description: str
    icon: str
    tier: str
    badge_line: None | str
    awarded_at: str
    rarity_pct: float | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        badge_id = self.badge_id

        name = self.name

        description = self.description

        icon = self.icon

        tier = self.tier

        badge_line: None | str
        badge_line = self.badge_line

        awarded_at = self.awarded_at

        rarity_pct: float | None
        rarity_pct = self.rarity_pct

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "badgeId": badge_id,
                "name": name,
                "description": description,
                "icon": icon,
                "tier": tier,
                "badgeLine": badge_line,
                "awardedAt": awarded_at,
                "rarityPct": rarity_pct,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        badge_id = d.pop("badgeId")

        name = d.pop("name")

        description = d.pop("description")

        icon = d.pop("icon")

        tier = d.pop("tier")

        def _parse_badge_line(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        badge_line = _parse_badge_line(d.pop("badgeLine"))

        awarded_at = d.pop("awardedAt")

        def _parse_rarity_pct(data: object) -> float | None:
            if data is None:
                return data
            return cast(float | None, data)

        rarity_pct = _parse_rarity_pct(d.pop("rarityPct"))

        subject_sheet_badges_item = cls(
            badge_id=badge_id,
            name=name,
            description=description,
            icon=icon,
            tier=tier,
            badge_line=badge_line,
            awarded_at=awarded_at,
            rarity_pct=rarity_pct,
        )

        subject_sheet_badges_item.additional_properties = d
        return subject_sheet_badges_item

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
