from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProductAdminCustomersByIdPauseResponse200")


@_attrs_define
class PostV1ProductAdminCustomersByIdPauseResponse200:
    """
    Attributes:
        paused (bool):
        object_ (Literal['product_admin.customer'] | Unset):
    """

    paused: bool
    object_: Literal["product_admin.customer"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        paused = self.paused

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "paused": paused,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        paused = d.pop("paused")

        object_ = cast(Literal["product_admin.customer"] | Unset, d.pop("object", UNSET))
        if object_ != "product_admin.customer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'product_admin.customer', got '{object_}'")

        post_v1_product_admin_customers_by_id_pause_response_200 = cls(
            paused=paused,
            object_=object_,
        )

        post_v1_product_admin_customers_by_id_pause_response_200.additional_properties = d
        return post_v1_product_admin_customers_by_id_pause_response_200

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
