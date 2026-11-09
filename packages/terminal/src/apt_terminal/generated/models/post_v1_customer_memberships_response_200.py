from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CustomerMembershipsResponse200")


@_attrs_define
class PostV1CustomerMembershipsResponse200:
    """
    Attributes:
        object_ (Literal['customer_membership'] | Unset):
        user_id (str | Unset):
        customer_id (str | Unset):
        ecosystem_id (str | Unset):
        created (bool | Unset): false when they were already a member
    """

    object_: Literal["customer_membership"] | Unset = UNSET
    user_id: str | Unset = UNSET
    customer_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    created: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        user_id = self.user_id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if user_id is not UNSET:
            field_dict["user_id"] = user_id
        if customer_id is not UNSET:
            field_dict["customer_id"] = customer_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if created is not UNSET:
            field_dict["created"] = created

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        object_ = cast(Literal["customer_membership"] | Unset, d.pop("object", UNSET))
        if object_ != "customer_membership" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'customer_membership', got '{object_}'")

        user_id = d.pop("user_id", UNSET)

        customer_id = d.pop("customer_id", UNSET)

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        created = d.pop("created", UNSET)

        post_v1_customer_memberships_response_200 = cls(
            object_=object_,
            user_id=user_id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
            created=created,
        )

        post_v1_customer_memberships_response_200.additional_properties = d
        return post_v1_customer_memberships_response_200

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
