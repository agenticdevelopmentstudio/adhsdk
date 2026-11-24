from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_bucket_access_groups_by_id_members_body_member_type import (
    PostV1BucketAccessGroupsByIdMembersBodyMemberType,
)

T = TypeVar("T", bound="PostV1BucketAccessGroupsByIdMembersBody")


@_attrs_define
class PostV1BucketAccessGroupsByIdMembersBody:
    """
    Attributes:
        member_type (PostV1BucketAccessGroupsByIdMembersBodyMemberType):
        member_id (str):
    """

    member_type: PostV1BucketAccessGroupsByIdMembersBodyMemberType
    member_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        member_type = self.member_type.value

        member_id = self.member_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "member_type": member_type,
                "member_id": member_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        member_type = PostV1BucketAccessGroupsByIdMembersBodyMemberType(d.pop("member_type"))

        member_id = d.pop("member_id")

        post_v1_bucket_access_groups_by_id_members_body = cls(
            member_type=member_type,
            member_id=member_id,
        )

        post_v1_bucket_access_groups_by_id_members_body.additional_properties = d
        return post_v1_bucket_access_groups_by_id_members_body

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
