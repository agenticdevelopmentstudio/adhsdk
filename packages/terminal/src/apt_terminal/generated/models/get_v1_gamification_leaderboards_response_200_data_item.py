from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1GamificationLeaderboardsResponse200DataItem")


@_attrs_define
class GetV1GamificationLeaderboardsResponse200DataItem:
    """
    Attributes:
        subject_type (str):
        subject_id (str):
        avatar_url (str):
        total_points (int):
        name (None | str | Unset): Display name (users only)
        level (None | str | Unset):
        object_ (Literal['gamification.leaderboard'] | Unset):
    """

    subject_type: str
    subject_id: str
    avatar_url: str
    total_points: int
    name: None | str | Unset = UNSET
    level: None | str | Unset = UNSET
    object_: Literal["gamification.leaderboard"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type

        subject_id = self.subject_id

        avatar_url = self.avatar_url

        total_points = self.total_points

        name: None | str | Unset
        if isinstance(self.name, Unset):
            name = UNSET
        else:
            name = self.name

        level: None | str | Unset
        if isinstance(self.level, Unset):
            level = UNSET
        else:
            level = self.level

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "avatar_url": avatar_url,
                "total_points": total_points,
            }
        )
        if name is not UNSET:
            field_dict["name"] = name
        if level is not UNSET:
            field_dict["level"] = level
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_type = d.pop("subject_type")

        subject_id = d.pop("subject_id")

        avatar_url = d.pop("avatar_url")

        total_points = d.pop("total_points")

        def _parse_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        name = _parse_name(d.pop("name", UNSET))

        def _parse_level(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        level = _parse_level(d.pop("level", UNSET))

        object_ = cast(Literal["gamification.leaderboard"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.leaderboard" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.leaderboard', got '{object_}'")

        get_v1_gamification_leaderboards_response_200_data_item = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            avatar_url=avatar_url,
            total_points=total_points,
            name=name,
            level=level,
            object_=object_,
        )

        get_v1_gamification_leaderboards_response_200_data_item.additional_properties = d
        return get_v1_gamification_leaderboards_response_200_data_item

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
