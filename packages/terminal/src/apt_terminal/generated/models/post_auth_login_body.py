from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostAuthLoginBody")


@_attrs_define
class PostAuthLoginBody:
    """
    Attributes:
        password (str):
        email (str | Unset): Email address
        slug (str | Unset): User id (login handle)
        identifier (str | Unset): Email, user id, or a verified phone number (E.164) — classified server-side
    """

    password: str
    email: str | Unset = UNSET
    slug: str | Unset = UNSET
    identifier: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        password = self.password

        email = self.email

        slug = self.slug

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
        if slug is not UNSET:
            field_dict["slug"] = slug
        if identifier is not UNSET:
            field_dict["identifier"] = identifier

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        password = d.pop("password")

        email = d.pop("email", UNSET)

        slug = d.pop("slug", UNSET)

        identifier = d.pop("identifier", UNSET)

        post_auth_login_body = cls(
            password=password,
            email=email,
            slug=slug,
            identifier=identifier,
        )

        post_auth_login_body.additional_properties = d
        return post_auth_login_body

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
