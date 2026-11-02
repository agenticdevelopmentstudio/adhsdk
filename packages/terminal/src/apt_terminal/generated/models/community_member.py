from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="CommunityMember")


@_attrs_define
class CommunityMember:
    """
    Attributes:
        community_id (str):
        customer_id (str):
        role (str): owner | admin | moderator | member
        created_at (str):
        updated_at (str):
        bio (None | str | Unset): The member’s one-line "what I’m building" intro for this community.
    """

    community_id: str
    customer_id: str
    role: str
    created_at: str
    updated_at: str
    bio: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        community_id = self.community_id

        customer_id = self.customer_id

        role = self.role

        created_at = self.created_at

        updated_at = self.updated_at

        bio: None | str | Unset
        if isinstance(self.bio, Unset):
            bio = UNSET
        else:
            bio = self.bio

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "communityId": community_id,
                "customerId": customer_id,
                "role": role,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if bio is not UNSET:
            field_dict["bio"] = bio

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        community_id = d.pop("communityId")

        customer_id = d.pop("customerId")

        role = d.pop("role")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_bio(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        bio = _parse_bio(d.pop("bio", UNSET))

        community_member = cls(
            community_id=community_id,
            customer_id=customer_id,
            role=role,
            created_at=created_at,
            updated_at=updated_at,
            bio=bio,
        )

        community_member.additional_properties = d
        return community_member

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
