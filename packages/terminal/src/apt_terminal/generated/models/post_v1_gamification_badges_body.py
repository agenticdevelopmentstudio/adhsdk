from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_realm_badge_input_comparator import GamificationRealmBadgeInputComparator
from ..models.gamification_realm_badge_input_tier import GamificationRealmBadgeInputTier
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamificationBadgesBody")


@_attrs_define
class PostV1GamificationBadgesBody:
    """
    Attributes:
        name (str):
        description (str):
        icon (str):
        stat_key (str):
        threshold (int):
        badge_line (str):
        tier (GamificationRealmBadgeInputTier):
        point_value (int):
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
        comparator (GamificationRealmBadgeInputComparator | Unset):  Default:
            GamificationRealmBadgeInputComparator.VALUE_0.
        hidden (bool | Unset):  Default: False.
    """

    name: str
    description: str
    icon: str
    stat_key: str
    threshold: int
    badge_line: str
    tier: GamificationRealmBadgeInputTier
    point_value: int
    ecosystem: str
    comparator: GamificationRealmBadgeInputComparator | Unset = (
        GamificationRealmBadgeInputComparator.VALUE_0
    )
    hidden: bool | Unset = False
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        icon = self.icon

        stat_key = self.stat_key

        threshold = self.threshold

        badge_line = self.badge_line

        tier = self.tier.value

        point_value = self.point_value

        ecosystem = self.ecosystem

        comparator: str | Unset = UNSET
        if not isinstance(self.comparator, Unset):
            comparator = self.comparator.value

        hidden = self.hidden

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "description": description,
                "icon": icon,
                "stat_key": stat_key,
                "threshold": threshold,
                "badge_line": badge_line,
                "tier": tier,
                "point_value": point_value,
                "ecosystem": ecosystem,
            }
        )
        if comparator is not UNSET:
            field_dict["comparator"] = comparator
        if hidden is not UNSET:
            field_dict["hidden"] = hidden

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        description = d.pop("description")

        icon = d.pop("icon")

        stat_key = d.pop("stat_key")

        threshold = d.pop("threshold")

        badge_line = d.pop("badge_line")

        tier = GamificationRealmBadgeInputTier(d.pop("tier"))

        point_value = d.pop("point_value")

        ecosystem = d.pop("ecosystem")

        _comparator = d.pop("comparator", UNSET)
        comparator: GamificationRealmBadgeInputComparator | Unset
        if isinstance(_comparator, Unset):
            comparator = UNSET
        else:
            comparator = GamificationRealmBadgeInputComparator(_comparator)

        hidden = d.pop("hidden", UNSET)

        post_v1_gamification_badges_body = cls(
            name=name,
            description=description,
            icon=icon,
            stat_key=stat_key,
            threshold=threshold,
            badge_line=badge_line,
            tier=tier,
            point_value=point_value,
            ecosystem=ecosystem,
            comparator=comparator,
            hidden=hidden,
        )

        post_v1_gamification_badges_body.additional_properties = d
        return post_v1_gamification_badges_body

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
