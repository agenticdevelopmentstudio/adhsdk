from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CustomerSessionsRefreshResponse200")


@_attrs_define
class PostV1CustomerSessionsRefreshResponse200:
    """
    Attributes:
        token (str): End-customer access token (typ='customer' JWT, short-lived)
        refresh_token (str): Opaque customer-session refresh token (single-use; rotated on refresh)
        customer_id (str): The end-customer id
        object_ (Literal['customer_session'] | Unset):
    """

    token: str
    refresh_token: str
    customer_id: str
    object_: Literal["customer_session"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        refresh_token = self.refresh_token

        customer_id = self.customer_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "refresh_token": refresh_token,
                "customer_id": customer_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        refresh_token = d.pop("refresh_token")

        customer_id = d.pop("customer_id")

        object_ = cast(Literal["customer_session"] | Unset, d.pop("object", UNSET))
        if object_ != "customer_session" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'customer_session', got '{object_}'")

        post_v1_customer_sessions_refresh_response_200 = cls(
            token=token,
            refresh_token=refresh_token,
            customer_id=customer_id,
            object_=object_,
        )

        post_v1_customer_sessions_refresh_response_200.additional_properties = d
        return post_v1_customer_sessions_refresh_response_200

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
