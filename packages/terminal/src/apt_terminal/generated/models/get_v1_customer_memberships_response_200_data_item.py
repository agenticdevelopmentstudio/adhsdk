from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1CustomerMembershipsResponse200DataItem")


@_attrs_define
class GetV1CustomerMembershipsResponse200DataItem:
    """
    Attributes:
        object_ (Literal['customer_membership'] | Unset):
        user_id (str | Unset): the customer id the caller asked about
        customer_id (str | Unset): the customer row that carries this membership — what a removal deletes
        ecosystem_id (str | Unset):
    """

    object_: Literal["customer_membership"] | Unset = UNSET
    user_id: str | Unset = UNSET
    customer_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        user_id = self.user_id

        customer_id = self.customer_id

        ecosystem_id = self.ecosystem_id

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

        get_v1_customer_memberships_response_200_data_item = cls(
            object_=object_,
            user_id=user_id,
            customer_id=customer_id,
            ecosystem_id=ecosystem_id,
        )

        get_v1_customer_memberships_response_200_data_item.additional_properties = d
        return get_v1_customer_memberships_response_200_data_item

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
