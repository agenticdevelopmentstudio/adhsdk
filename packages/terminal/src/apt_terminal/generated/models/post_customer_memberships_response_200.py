from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostCustomerMembershipsResponse200")


@_attrs_define
class PostCustomerMembershipsResponse200:
    """
    Attributes:
        user_id (str | Unset):
        customer_id (str | Unset):
        ecosystem_id (str | Unset):
        created (bool | Unset): false when they were already a member
    """

    user_id: str | Unset = UNSET
    customer_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    created: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if user_id is not UNSET:
            field_dict["userId"] = user_id
        if customer_id is not UNSET:
            field_dict["customerId"] = customer_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if created is not UNSET:
            field_dict["created"] = created

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("userId", UNSET)

        customer_id = d.pop("customerId", UNSET)

        ecosystem_id = d.pop("ecosystemId", UNSET)

        created = d.pop("created", UNSET)

        post_customer_memberships_response_200 = cls(
            user_id=user_id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
            created=created,
        )

        post_customer_memberships_response_200.additional_properties = d
        return post_customer_memberships_response_200

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
