from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetCustomerMembershipsResponse200Item")


@_attrs_define
class GetCustomerMembershipsResponse200Item:
    """
    Attributes:
        user_id (str | Unset): the customer id the caller asked about
        customer_id (str | Unset): the customer row that carries this membership — what a removal deletes
        ecosystem_id (str | Unset):
    """

    user_id: str | Unset = UNSET
    customer_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if user_id is not UNSET:
            field_dict["userId"] = user_id
        if customer_id is not UNSET:
            field_dict["customerId"] = customer_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("userId", UNSET)

        customer_id = d.pop("customerId", UNSET)

        ecosystem_id = d.pop("ecosystemId", UNSET)

        get_customer_memberships_response_200_item = cls(
            user_id=user_id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
        )

        get_customer_memberships_response_200_item.additional_properties = d
        return get_customer_memberships_response_200_item

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
