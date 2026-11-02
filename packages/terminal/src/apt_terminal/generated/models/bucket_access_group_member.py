from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.bucket_access_group_member_member_type import BucketAccessGroupMemberMemberType

T = TypeVar("T", bound="BucketAccessGroupMember")


@_attrs_define
class BucketAccessGroupMember:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        access_group_id (str):
        member_type (BucketAccessGroupMemberMemberType):
        member_id (str):
        created_at (str):
        updated_at (str):
    """

    id: str
    ecosystem_id: str
    access_group_id: str
    member_type: BucketAccessGroupMemberMemberType
    member_id: str
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        access_group_id = self.access_group_id

        member_type = self.member_type.value

        member_id = self.member_id

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "accessGroupId": access_group_id,
                "memberType": member_type,
                "memberId": member_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        access_group_id = d.pop("accessGroupId")

        member_type = BucketAccessGroupMemberMemberType(d.pop("memberType"))

        member_id = d.pop("memberId")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        bucket_access_group_member = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            access_group_id=access_group_id,
            member_type=member_type,
            member_id=member_id,
            created_at=created_at,
            updated_at=updated_at,
        )

        bucket_access_group_member.additional_properties = d
        return bucket_access_group_member

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
