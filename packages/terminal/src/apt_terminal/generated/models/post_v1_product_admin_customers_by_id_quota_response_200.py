from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProductAdminCustomersByIdQuotaResponse200")


@_attrs_define
class PostV1ProductAdminCustomersByIdQuotaResponse200:
    """
    Attributes:
        quota_bytes (int):
        object_ (Literal['product_admin.customer'] | Unset):
    """

    quota_bytes: int
    object_: Literal["product_admin.customer"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        quota_bytes = self.quota_bytes

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "quota_bytes": quota_bytes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        quota_bytes = d.pop("quota_bytes")

        object_ = cast(Literal["product_admin.customer"] | Unset, d.pop("object", UNSET))
        if object_ != "product_admin.customer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'product_admin.customer', got '{object_}'")

        post_v1_product_admin_customers_by_id_quota_response_200 = cls(
            quota_bytes=quota_bytes,
            object_=object_,
        )

        post_v1_product_admin_customers_by_id_quota_response_200.additional_properties = d
        return post_v1_product_admin_customers_by_id_quota_response_200

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
