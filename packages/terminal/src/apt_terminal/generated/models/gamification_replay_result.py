from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GamificationReplayResult")


@_attrs_define
class GamificationReplayResult:
    """
    Attributes:
        subjects (int): Subjects touched (1 for a single-subject replay)
        badges (int): Newly-granted badges across the replayed subject(s)
        xp_gained (int | Unset): Points granted — single-subject replay only
    """

    subjects: int
    badges: int
    xp_gained: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subjects = self.subjects

        badges = self.badges

        xp_gained = self.xp_gained

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subjects": subjects,
                "badges": badges,
            }
        )
        if xp_gained is not UNSET:
            field_dict["xpGained"] = xp_gained

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subjects = d.pop("subjects")

        badges = d.pop("badges")

        xp_gained = d.pop("xpGained", UNSET)

        gamification_replay_result = cls(
            subjects=subjects,
            badges=badges,
            xp_gained=xp_gained,
        )

        gamification_replay_result.additional_properties = d
        return gamification_replay_result

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
