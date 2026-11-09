from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.bucket_access_group_member_member_type import BucketAccessGroupMemberMemberType
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BucketAccessGroupsByIdMembersResponse201")


@_attrs_define
class PostV1BucketAccessGroupsByIdMembersResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        access_group_id (str):
        member_type (BucketAccessGroupMemberMemberType):
        member_id (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['member'] | Unset):
    """

    id: str
    ecosystem_id: str
    access_group_id: str
    member_type: BucketAccessGroupMemberMemberType
    member_id: str
    created: int
    updated: int
    object_: Literal["member"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        access_group_id = self.access_group_id

        member_type = self.member_type.value

        member_id = self.member_id

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "access_group_id": access_group_id,
                "member_type": member_type,
                "member_id": member_id,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        access_group_id = d.pop("access_group_id")

        member_type = BucketAccessGroupMemberMemberType(d.pop("member_type"))

        member_id = d.pop("member_id")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["member"] | Unset, d.pop("object", UNSET))
        if object_ != "member" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'member', got '{object_}'")

        post_v1_bucket_access_groups_by_id_members_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            access_group_id=access_group_id,
            member_type=member_type,
            member_id=member_id,
            created=created,
            updated=updated,
            object_=object_,
        )

        post_v1_bucket_access_groups_by_id_members_response_201.additional_properties = d
        return post_v1_bucket_access_groups_by_id_members_response_201

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
