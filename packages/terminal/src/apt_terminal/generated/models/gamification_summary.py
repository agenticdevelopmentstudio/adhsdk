from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.gamification_subject_badge import GamificationSubjectBadge


T = TypeVar("T", bound="GamificationSummary")


@_attrs_define
class GamificationSummary:
    """
    Attributes:
        subject_type (str):
        subject_id (str):
        total_points (int):
        opted_out (bool):
        badges (list[GamificationSubjectBadge]):
        level (None | str | Unset):
    """

    subject_type: str
    subject_id: str
    total_points: int
    opted_out: bool
    badges: list[GamificationSubjectBadge]
    level: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type

        subject_id = self.subject_id

        total_points = self.total_points

        opted_out = self.opted_out

        badges = []
        for badges_item_data in self.badges:
            badges_item = badges_item_data.to_dict()
            badges.append(badges_item)

        level: None | str | Unset
        if isinstance(self.level, Unset):
            level = UNSET
        else:
            level = self.level

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subjectType": subject_type,
                "subjectId": subject_id,
                "totalPoints": total_points,
                "optedOut": opted_out,
                "badges": badges,
            }
        )
        if level is not UNSET:
            field_dict["level"] = level

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_subject_badge import GamificationSubjectBadge

        d = dict(src_dict)
        subject_type = d.pop("subjectType")

        subject_id = d.pop("subjectId")

        total_points = d.pop("totalPoints")

        opted_out = d.pop("optedOut")

        badges = []
        _badges = d.pop("badges")
        for badges_item_data in _badges:
            badges_item = GamificationSubjectBadge.from_dict(badges_item_data)

            badges.append(badges_item)

        def _parse_level(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        level = _parse_level(d.pop("level", UNSET))

        gamification_summary = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            total_points=total_points,
            opted_out=opted_out,
            badges=badges,
            level=level,
        )

        gamification_summary.additional_properties = d
        return gamification_summary

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
