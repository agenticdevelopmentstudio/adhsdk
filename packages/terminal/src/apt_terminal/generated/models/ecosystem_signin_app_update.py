from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="EcosystemSigninAppUpdate")


@_attrs_define
class EcosystemSigninAppUpdate:
    """A partial update — supply at least one field. `slug` and the owning ecosystem are deliberately not patchable: both
    are identity, not configuration.

        Attributes:
            name (str | Unset):
            allowed_return_origins (list[str] | Unset):
            github_enabled (bool | Unset):
            redirect_uris (list[str] | Unset): OAuth redirect URIs for the app’s Hydra PKCE client: https, loopback http
                (localhost, 127.0.0.1, [::1]), or a private-use native scheme (com.example.app:/cb). No fragment, no
                credentials. Anything else is a 400.
    """

    name: str | Unset = UNSET
    allowed_return_origins: list[str] | Unset = UNSET
    github_enabled: bool | Unset = UNSET
    redirect_uris: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        allowed_return_origins: list[str] | Unset = UNSET
        if not isinstance(self.allowed_return_origins, Unset):
            allowed_return_origins = self.allowed_return_origins

        github_enabled = self.github_enabled

        redirect_uris: list[str] | Unset = UNSET
        if not isinstance(self.redirect_uris, Unset):
            redirect_uris = self.redirect_uris

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if allowed_return_origins is not UNSET:
            field_dict["allowedReturnOrigins"] = allowed_return_origins
        if github_enabled is not UNSET:
            field_dict["githubEnabled"] = github_enabled
        if redirect_uris is not UNSET:
            field_dict["redirectUris"] = redirect_uris

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        allowed_return_origins = cast(list[str], d.pop("allowedReturnOrigins", UNSET))

        github_enabled = d.pop("githubEnabled", UNSET)

        redirect_uris = cast(list[str], d.pop("redirectUris", UNSET))

        ecosystem_signin_app_update = cls(
            name=name,
            allowed_return_origins=allowed_return_origins,
            github_enabled=github_enabled,
            redirect_uris=redirect_uris,
        )

        ecosystem_signin_app_update.additional_properties = d
        return ecosystem_signin_app_update

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
