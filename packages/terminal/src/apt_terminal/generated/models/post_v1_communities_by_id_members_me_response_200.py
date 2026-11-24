from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CommunitiesByIdMembersMeResponse200")


@_attrs_define
class PostV1CommunitiesByIdMembersMeResponse200:
    """
    Attributes:
        community_id (str):
        customer_id (str):
        role (str): owner | admin | moderator | member
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        bio (None | str | Unset): The member’s one-line "what I’m building" intro for this community.
        object_ (Literal['member'] | Unset):
    """

    community_id: str
    customer_id: str
    role: str
    created: int
    updated: int
    bio: None | str | Unset = UNSET
    object_: Literal["member"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        community_id = self.community_id

        customer_id = self.customer_id

        role = self.role

        created = self.created

        updated = self.updated

        bio: None | str | Unset
        if isinstance(self.bio, Unset):
            bio = UNSET
        else:
            bio = self.bio

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "community_id": community_id,
                "customer_id": customer_id,
                "role": role,
                "created": created,
                "updated": updated,
            }
        )
        if bio is not UNSET:
            field_dict["bio"] = bio
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        community_id = d.pop("community_id")

        customer_id = d.pop("customer_id")

        role = d.pop("role")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_bio(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        bio = _parse_bio(d.pop("bio", UNSET))

        object_ = cast(Literal["member"] | Unset, d.pop("object", UNSET))
        if object_ != "member" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'member', got '{object_}'")

        post_v1_communities_by_id_members_me_response_200 = cls(
            community_id=community_id,
            customer_id=customer_id,
            role=role,
            created=created,
            updated=updated,
            bio=bio,
            object_=object_,
        )

        post_v1_communities_by_id_members_me_response_200.additional_properties = d
        return post_v1_communities_by_id_members_me_response_200

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
