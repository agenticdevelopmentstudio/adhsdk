from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostCustomerLoginBody")


@_attrs_define
class PostCustomerLoginBody:
    """email or identifier is required (identifier is the generic alias).

    Attributes:
        password (str):
        email (str | Unset):
        identifier (str | Unset):
    """

    password: str
    email: str | Unset = UNSET
    identifier: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        password = self.password

        email = self.email

        identifier = self.identifier

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "password": password,
            }
        )
        if email is not UNSET:
            field_dict["email"] = email
        if identifier is not UNSET:
            field_dict["identifier"] = identifier

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        password = d.pop("password")

        email = d.pop("email", UNSET)

        identifier = d.pop("identifier", UNSET)

        post_customer_login_body = cls(
            password=password,
            email=email,
            identifier=identifier,
        )

        post_customer_login_body.additional_properties = d
        return post_customer_login_body

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
