from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="DeleteCustomerMembershipsCustomerIdResponse200")


@_attrs_define
class DeleteCustomerMembershipsCustomerIdResponse200:
    """
    Attributes:
        customer_id (str | Unset):
        ecosystem_id (str | Unset):
        removed (bool | Unset):
    """

    customer_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    removed: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

        removed = self.removed

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if customer_id is not UNSET:
            field_dict["customerId"] = customer_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if removed is not UNSET:
            field_dict["removed"] = removed

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        customer_id = d.pop("customerId", UNSET)

        ecosystem_id = d.pop("ecosystemId", UNSET)

        removed = d.pop("removed", UNSET)

        delete_customer_memberships_customer_id_response_200 = cls(
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
            removed=removed,
        )

        delete_customer_memberships_customer_id_response_200.additional_properties = d
        return delete_customer_memberships_customer_id_response_200

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
