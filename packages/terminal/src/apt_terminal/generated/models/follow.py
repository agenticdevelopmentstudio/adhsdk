from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="Follow")


@_attrs_define
class Follow:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        follower_id (str):
        followee_id (str):
        created_at (str):
    """

    id: str
    ecosystem_id: str
    follower_id: str
    followee_id: str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        follower_id = self.follower_id

        followee_id = self.followee_id

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "followerId": follower_id,
                "followeeId": followee_id,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        follower_id = d.pop("followerId")

        followee_id = d.pop("followeeId")

        created_at = d.pop("createdAt")

        follow = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            follower_id=follower_id,
            followee_id=followee_id,
            created_at=created_at,
        )

        follow.additional_properties = d
        return follow

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
