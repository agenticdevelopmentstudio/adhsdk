from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="CustomerAuthResult")


@_attrs_define
class CustomerAuthResult:
    """
    Attributes:
        token (str): End-customer access token (typ='customer' JWT, short-lived)
        refresh_token (str): Opaque customer-session refresh token (single-use; rotated on refresh)
        customer_id (str): The end-customer id
    """

    token: str
    refresh_token: str
    customer_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        refresh_token = self.refresh_token

        customer_id = self.customer_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "refreshToken": refresh_token,
                "customerId": customer_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        refresh_token = d.pop("refreshToken")

        customer_id = d.pop("customerId")

        customer_auth_result = cls(
            token=token,
            refresh_token=refresh_token,
            customer_id=customer_id,
        )

        customer_auth_result.additional_properties = d
        return customer_auth_result

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
