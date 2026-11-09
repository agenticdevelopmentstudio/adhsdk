from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_sheet_subject_type import PersonaSheetSubjectType

if TYPE_CHECKING:
    from ..models.persona_sheet_badges_item import PersonaSheetBadgesItem
    from ..models.persona_sheet_stats import PersonaSheetStats
    from ..models.persona_sheet_trend import PersonaSheetTrend


T = TypeVar("T", bound="PersonaSheet")


@_attrs_define
class PersonaSheet:
    """
    Attributes:
        subject_type (PersonaSheetSubjectType):
        subject_id (str):
        skin (str):
        xp (int):
        level (int):
        level_title (None | str):
        xp_into_level (int):
        xp_for_next (int):
        tenure_days (int):
        streak_days (int):
        stats (PersonaSheetStats):
        trend (PersonaSheetTrend):
        badges (list[PersonaSheetBadgesItem]):
    """

    subject_type: PersonaSheetSubjectType
    subject_id: str
    skin: str
    xp: int
    level: int
    level_title: None | str
    xp_into_level: int
    xp_for_next: int
    tenure_days: int
    streak_days: int
    stats: PersonaSheetStats
    trend: PersonaSheetTrend
    badges: list[PersonaSheetBadgesItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type.value

        subject_id = self.subject_id

        skin = self.skin

        xp = self.xp

        level = self.level

        level_title: None | str
        level_title = self.level_title

        xp_into_level = self.xp_into_level

        xp_for_next = self.xp_for_next

        tenure_days = self.tenure_days

        streak_days = self.streak_days

        stats = self.stats.to_dict()

        trend = self.trend.to_dict()

        badges = []
        for badges_item_data in self.badges:
            badges_item = badges_item_data.to_dict()
            badges.append(badges_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "skin": skin,
                "xp": xp,
                "level": level,
                "level_title": level_title,
                "xp_into_level": xp_into_level,
                "xp_for_next": xp_for_next,
                "tenure_days": tenure_days,
                "streak_days": streak_days,
                "stats": stats,
                "trend": trend,
                "badges": badges,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_sheet_badges_item import PersonaSheetBadgesItem
        from ..models.persona_sheet_stats import PersonaSheetStats
        from ..models.persona_sheet_trend import PersonaSheetTrend

        d = dict(src_dict)
        subject_type = PersonaSheetSubjectType(d.pop("subject_type"))

        subject_id = d.pop("subject_id")

        skin = d.pop("skin")

        xp = d.pop("xp")

        level = d.pop("level")

        def _parse_level_title(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        level_title = _parse_level_title(d.pop("level_title"))

        xp_into_level = d.pop("xp_into_level")

        xp_for_next = d.pop("xp_for_next")

        tenure_days = d.pop("tenure_days")

        streak_days = d.pop("streak_days")

        stats = PersonaSheetStats.from_dict(d.pop("stats"))

        trend = PersonaSheetTrend.from_dict(d.pop("trend"))

        badges = []
        _badges = d.pop("badges")
        for badges_item_data in _badges:
            badges_item = PersonaSheetBadgesItem.from_dict(badges_item_data)

            badges.append(badges_item)

        persona_sheet = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            skin=skin,
            xp=xp,
            level=level,
            level_title=level_title,
            xp_into_level=xp_into_level,
            xp_for_next=xp_for_next,
            tenure_days=tenure_days,
            streak_days=streak_days,
            stats=stats,
            trend=trend,
            badges=badges,
        )

        persona_sheet.additional_properties = d
        return persona_sheet

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
