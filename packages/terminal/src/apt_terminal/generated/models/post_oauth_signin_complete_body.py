from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostOauthSigninCompleteBody")


@_attrs_define
class PostOauthSigninCompleteBody:
    """
    Attributes:
        client_slug (str):
        provider_slug (str):
        code (str | Unset):
        access_token (str | Unset):
        id_token (str | Unset):
        redirect_uri (str | Unset):
    """

    client_slug: str
    provider_slug: str
    code: str | Unset = UNSET
    access_token: str | Unset = UNSET
    id_token: str | Unset = UNSET
    redirect_uri: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_slug = self.client_slug

        provider_slug = self.provider_slug

        code = self.code

        access_token = self.access_token

        id_token = self.id_token

        redirect_uri = self.redirect_uri

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "clientSlug": client_slug,
                "providerSlug": provider_slug,
            }
        )
        if code is not UNSET:
            field_dict["code"] = code
        if access_token is not UNSET:
            field_dict["accessToken"] = access_token
        if id_token is not UNSET:
            field_dict["idToken"] = id_token
        if redirect_uri is not UNSET:
            field_dict["redirectUri"] = redirect_uri

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        client_slug = d.pop("clientSlug")

        provider_slug = d.pop("providerSlug")

        code = d.pop("code", UNSET)

        access_token = d.pop("accessToken", UNSET)

        id_token = d.pop("idToken", UNSET)

        redirect_uri = d.pop("redirectUri", UNSET)

        post_oauth_signin_complete_body = cls(
            client_slug=client_slug,
            provider_slug=provider_slug,
            code=code,
            access_token=access_token,
            id_token=id_token,
            redirect_uri=redirect_uri,
        )

        post_oauth_signin_complete_body.additional_properties = d
        return post_oauth_signin_complete_body

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
