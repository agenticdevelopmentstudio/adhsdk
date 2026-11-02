from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.gamification_catalog_badge_source import GamificationCatalogBadgeSource
from ..models.gamification_realm_badge_comparator_type_1 import (
    GamificationRealmBadgeComparatorType1,
)
from ..models.gamification_realm_badge_comparator_type_2_type_1 import (
    GamificationRealmBadgeComparatorType2Type1,
)
from ..models.gamification_realm_badge_comparator_type_3_type_1 import (
    GamificationRealmBadgeComparatorType3Type1,
)
from ..models.gamification_realm_badge_tier_type_1 import GamificationRealmBadgeTierType1
from ..models.gamification_realm_badge_tier_type_2_type_1 import (
    GamificationRealmBadgeTierType2Type1,
)
from ..models.gamification_realm_badge_tier_type_3_type_1 import (
    GamificationRealmBadgeTierType3Type1,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GamificationCatalogBadge")


@_attrs_define
class GamificationCatalogBadge:
    """
    Attributes:
        id (str):
        name (str):
        description (str):
        icon (str):
        point_value (int): XP granted when earned
        source (GamificationCatalogBadgeSource): 'realm' when a realm row shadows the same-slot default
        stat_key (None | str | Unset): The stat the rule watches
        comparator (GamificationRealmBadgeComparatorType1 | GamificationRealmBadgeComparatorType2Type1 |
            GamificationRealmBadgeComparatorType3Type1 | None | Unset):
        threshold (int | None | Unset):
        badge_line (None | str | Unset): Groups the tiers of one line
        tier (GamificationRealmBadgeTierType1 | GamificationRealmBadgeTierType2Type1 |
            GamificationRealmBadgeTierType3Type1 | None | Unset):
        hidden (bool | Unset):
        active (bool | Unset):
        subject_type (None | str | Unset):
        ecosystem_id (None | str | Unset): NULL = platform default; else the realm
    """

    id: str
    name: str
    description: str
    icon: str
    point_value: int
    source: GamificationCatalogBadgeSource
    stat_key: None | str | Unset = UNSET
    comparator: (
        GamificationRealmBadgeComparatorType1
        | GamificationRealmBadgeComparatorType2Type1
        | GamificationRealmBadgeComparatorType3Type1
        | None
        | Unset
    ) = UNSET
    threshold: int | None | Unset = UNSET
    badge_line: None | str | Unset = UNSET
    tier: (
        GamificationRealmBadgeTierType1
        | GamificationRealmBadgeTierType2Type1
        | GamificationRealmBadgeTierType3Type1
        | None
        | Unset
    ) = UNSET
    hidden: bool | Unset = UNSET
    active: bool | Unset = UNSET
    subject_type: None | str | Unset = UNSET
    ecosystem_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        description = self.description

        icon = self.icon

        point_value = self.point_value

        source = self.source.value

        stat_key: None | str | Unset
        if isinstance(self.stat_key, Unset):
            stat_key = UNSET
        else:
            stat_key = self.stat_key

        comparator: None | str | Unset
        if isinstance(self.comparator, Unset):
            comparator = UNSET
        elif (
            isinstance(self.comparator, GamificationRealmBadgeComparatorType1)
            or isinstance(self.comparator, GamificationRealmBadgeComparatorType2Type1)
            or isinstance(self.comparator, GamificationRealmBadgeComparatorType3Type1)
        ):
            comparator = self.comparator.value
        else:
            comparator = self.comparator

        threshold: int | None | Unset
        if isinstance(self.threshold, Unset):
            threshold = UNSET
        else:
            threshold = self.threshold

        badge_line: None | str | Unset
        if isinstance(self.badge_line, Unset):
            badge_line = UNSET
        else:
            badge_line = self.badge_line

        tier: None | str | Unset
        if isinstance(self.tier, Unset):
            tier = UNSET
        elif (
            isinstance(self.tier, GamificationRealmBadgeTierType1)
            or isinstance(self.tier, GamificationRealmBadgeTierType2Type1)
            or isinstance(self.tier, GamificationRealmBadgeTierType3Type1)
        ):
            tier = self.tier.value
        else:
            tier = self.tier

        hidden = self.hidden

        active = self.active

        subject_type: None | str | Unset
        if isinstance(self.subject_type, Unset):
            subject_type = UNSET
        else:
            subject_type = self.subject_type

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "description": description,
                "icon": icon,
                "pointValue": point_value,
                "source": source,
            }
        )
        if stat_key is not UNSET:
            field_dict["statKey"] = stat_key
        if comparator is not UNSET:
            field_dict["comparator"] = comparator
        if threshold is not UNSET:
            field_dict["threshold"] = threshold
        if badge_line is not UNSET:
            field_dict["badgeLine"] = badge_line
        if tier is not UNSET:
            field_dict["tier"] = tier
        if hidden is not UNSET:
            field_dict["hidden"] = hidden
        if active is not UNSET:
            field_dict["active"] = active
        if subject_type is not UNSET:
            field_dict["subjectType"] = subject_type
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        description = d.pop("description")

        icon = d.pop("icon")

        point_value = d.pop("pointValue")

        source = GamificationCatalogBadgeSource(d.pop("source"))

        def _parse_stat_key(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stat_key = _parse_stat_key(d.pop("statKey", UNSET))

        def _parse_comparator(
            data: object,
        ) -> (
            GamificationRealmBadgeComparatorType1
            | GamificationRealmBadgeComparatorType2Type1
            | GamificationRealmBadgeComparatorType3Type1
            | None
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                comparator_type_1 = GamificationRealmBadgeComparatorType1(data)

                return comparator_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                comparator_type_2_type_1 = GamificationRealmBadgeComparatorType2Type1(data)

                return comparator_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                comparator_type_3_type_1 = GamificationRealmBadgeComparatorType3Type1(data)

                return comparator_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GamificationRealmBadgeComparatorType1
                | GamificationRealmBadgeComparatorType2Type1
                | GamificationRealmBadgeComparatorType3Type1
                | None
                | Unset,
                data,
            )

        comparator = _parse_comparator(d.pop("comparator", UNSET))

        def _parse_threshold(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        threshold = _parse_threshold(d.pop("threshold", UNSET))

        def _parse_badge_line(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        badge_line = _parse_badge_line(d.pop("badgeLine", UNSET))

        def _parse_tier(
            data: object,
        ) -> (
            GamificationRealmBadgeTierType1
            | GamificationRealmBadgeTierType2Type1
            | GamificationRealmBadgeTierType3Type1
            | None
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                tier_type_1 = GamificationRealmBadgeTierType1(data)

                return tier_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                tier_type_2_type_1 = GamificationRealmBadgeTierType2Type1(data)

                return tier_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                tier_type_3_type_1 = GamificationRealmBadgeTierType3Type1(data)

                return tier_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GamificationRealmBadgeTierType1
                | GamificationRealmBadgeTierType2Type1
                | GamificationRealmBadgeTierType3Type1
                | None
                | Unset,
                data,
            )

        tier = _parse_tier(d.pop("tier", UNSET))

        hidden = d.pop("hidden", UNSET)

        active = d.pop("active", UNSET)

        def _parse_subject_type(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_type = _parse_subject_type(d.pop("subjectType", UNSET))

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId", UNSET))

        gamification_catalog_badge = cls(
            id=id,
            name=name,
            description=description,
            icon=icon,
            point_value=point_value,
            source=source,
            stat_key=stat_key,
            comparator=comparator,
            threshold=threshold,
            badge_line=badge_line,
            tier=tier,
            hidden=hidden,
            active=active,
            subject_type=subject_type,
            ecosystem_id=ecosystem_id,
        )

        gamification_catalog_badge.additional_properties = d
        return gamification_catalog_badge

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
