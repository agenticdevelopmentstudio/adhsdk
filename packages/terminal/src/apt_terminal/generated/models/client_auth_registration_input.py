from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ClientAuthRegistrationInput")


@_attrs_define
class ClientAuthRegistrationInput:
    """Creates the registration when there is none, updates it when there is. Origins must be bare http(s) origins and are
    stored canonical; redirect URIs are validated as OAuth redirect URIs. Up to 20 of each. For an application the
    platform shapes both: a web application redirects to https or loopback http; a native application may also use a
    custom scheme and has no return origins (any is a 400).

        Attributes:
            redirect_uris (list[str]):
            allowed_return_origins (list[str] | Unset): Omitted means none
    """

    redirect_uris: list[str]
    allowed_return_origins: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        redirect_uris = self.redirect_uris

        allowed_return_origins: list[str] | Unset = UNSET
        if not isinstance(self.allowed_return_origins, Unset):
            allowed_return_origins = self.allowed_return_origins

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "redirectUris": redirect_uris,
            }
        )
        if allowed_return_origins is not UNSET:
            field_dict["allowedReturnOrigins"] = allowed_return_origins

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        redirect_uris = cast(list[str], d.pop("redirectUris"))

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins", UNSET))

        client_auth_registration_input = cls(
            redirect_uris=redirect_uris,
            allowed_return_origins=allowed_return_origins,
        )

        client_auth_registration_input.additional_properties = d
        return client_auth_registration_input

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
