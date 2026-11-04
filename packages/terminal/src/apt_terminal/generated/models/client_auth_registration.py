from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="ClientAuthRegistration")


@_attrs_define
class ClientAuthRegistration:
    """A login registration: the OIDC client (a Hydra public PKCE client) a website or app signs customers in through.
    `clientId` is assigned by the server.

        Attributes:
            client_id (str): The OIDC client_id
            allowed_return_origins (list[str]):
            redirect_uris (list[str]):
    """

    client_id: str
    allowed_return_origins: list[str]
    redirect_uris: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_id = self.client_id

        allowed_return_origins = self.allowed_return_origins

        redirect_uris = self.redirect_uris

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "clientId": client_id,
                "allowedReturnOrigins": allowed_return_origins,
                "redirectUris": redirect_uris,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        client_id = d.pop("clientId")

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins"))

        redirect_uris = cast(list[str], d.pop("redirectUris"))

        client_auth_registration = cls(
            client_id=client_id,
            allowed_return_origins=allowed_return_origins,
            redirect_uris=redirect_uris,
        )

        client_auth_registration.additional_properties = d
        return client_auth_registration

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
