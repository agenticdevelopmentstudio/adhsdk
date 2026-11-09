from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamificationEventsReplayResponse200")


@_attrs_define
class PostV1GamificationEventsReplayResponse200:
    """
    Attributes:
        subjects (int): Subjects touched (1 for a single-subject replay)
        badges (int): Newly-granted badges across the replayed subject(s)
        xp_gained (int | Unset): Points granted — single-subject replay only
        object_ (Literal['gamification.event'] | Unset):
    """

    subjects: int
    badges: int
    xp_gained: int | Unset = UNSET
    object_: Literal["gamification.event"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subjects = self.subjects

        badges = self.badges

        xp_gained = self.xp_gained

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subjects": subjects,
                "badges": badges,
            }
        )
        if xp_gained is not UNSET:
            field_dict["xp_gained"] = xp_gained
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subjects = d.pop("subjects")

        badges = d.pop("badges")

        xp_gained = d.pop("xp_gained", UNSET)

        object_ = cast(Literal["gamification.event"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.event', got '{object_}'")

        post_v1_gamification_events_replay_response_200 = cls(
            subjects=subjects,
            badges=badges,
            xp_gained=xp_gained,
            object_=object_,
        )

        post_v1_gamification_events_replay_response_200.additional_properties = d
        return post_v1_gamification_events_replay_response_200

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
