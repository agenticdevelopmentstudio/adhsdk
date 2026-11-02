from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostGamificationReplayBody")


@_attrs_define
class PostGamificationReplayBody:
    """
    Attributes:
        ecosystem_id (str): The target realm to replay
        subject_type (str | Unset): With subjectId, replay just this one subject instead of the whole realm
        subject_id (str | Unset): Must be provided together with subjectType
    """

    ecosystem_id: str
    subject_type: str | Unset = UNSET
    subject_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        subject_type = self.subject_type

        subject_id = self.subject_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystemId": ecosystem_id,
            }
        )
        if subject_type is not UNSET:
            field_dict["subjectType"] = subject_type
        if subject_id is not UNSET:
            field_dict["subjectId"] = subject_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId")

        subject_type = d.pop("subjectType", UNSET)

        subject_id = d.pop("subjectId", UNSET)

        post_gamification_replay_body = cls(
            ecosystem_id=ecosystem_id,
            subject_type=subject_type,
            subject_id=subject_id,
        )

        post_gamification_replay_body.additional_properties = d
        return post_gamification_replay_body

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
