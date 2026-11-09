from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_oauth_providers_by_id_body_identity_mapping import (
        PostV1OauthProvidersByIdBodyIdentityMapping,
    )


T = TypeVar("T", bound="PostV1OauthProvidersByIdBody")


@_attrs_define
class PostV1OauthProvidersByIdBody:
    """
    Attributes:
        slug (str | Unset):
        display_name (str | Unset):
        client_id (str | Unset):
        client_secret (str | Unset):
        scopes (list[str] | Unset):
        authorize_url (None | str | Unset):
        token_url (None | str | Unset):
        userinfo_url (None | str | Unset):
        identity_mapping (PostV1OauthProvidersByIdBodyIdentityMapping | Unset):
    """

    slug: str | Unset = UNSET
    display_name: str | Unset = UNSET
    client_id: str | Unset = UNSET
    client_secret: str | Unset = UNSET
    scopes: list[str] | Unset = UNSET
    authorize_url: None | str | Unset = UNSET
    token_url: None | str | Unset = UNSET
    userinfo_url: None | str | Unset = UNSET
    identity_mapping: PostV1OauthProvidersByIdBodyIdentityMapping | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name = self.display_name

        client_id = self.client_id

        client_secret = self.client_secret

        scopes: list[str] | Unset = UNSET
        if not isinstance(self.scopes, Unset):
            scopes = self.scopes

        authorize_url: None | str | Unset
        if isinstance(self.authorize_url, Unset):
            authorize_url = UNSET
        else:
            authorize_url = self.authorize_url

        token_url: None | str | Unset
        if isinstance(self.token_url, Unset):
            token_url = UNSET
        else:
            token_url = self.token_url

        userinfo_url: None | str | Unset
        if isinstance(self.userinfo_url, Unset):
            userinfo_url = UNSET
        else:
            userinfo_url = self.userinfo_url

        identity_mapping: dict[str, Any] | Unset = UNSET
        if not isinstance(self.identity_mapping, Unset):
            identity_mapping = self.identity_mapping.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if client_id is not UNSET:
            field_dict["client_id"] = client_id
        if client_secret is not UNSET:
            field_dict["client_secret"] = client_secret
        if scopes is not UNSET:
            field_dict["scopes"] = scopes
        if authorize_url is not UNSET:
            field_dict["authorize_url"] = authorize_url
        if token_url is not UNSET:
            field_dict["token_url"] = token_url
        if userinfo_url is not UNSET:
            field_dict["userinfo_url"] = userinfo_url
        if identity_mapping is not UNSET:
            field_dict["identity_mapping"] = identity_mapping

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_oauth_providers_by_id_body_identity_mapping import (
            PostV1OauthProvidersByIdBodyIdentityMapping,
        )

        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        display_name = d.pop("display_name", UNSET)

        client_id = d.pop("client_id", UNSET)

        client_secret = d.pop("client_secret", UNSET)

        scopes = cast(list[str], d.pop("scopes", UNSET))

        def _parse_authorize_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        authorize_url = _parse_authorize_url(d.pop("authorize_url", UNSET))

        def _parse_token_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        token_url = _parse_token_url(d.pop("token_url", UNSET))

        def _parse_userinfo_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        userinfo_url = _parse_userinfo_url(d.pop("userinfo_url", UNSET))

        _identity_mapping = d.pop("identity_mapping", UNSET)
        identity_mapping: PostV1OauthProvidersByIdBodyIdentityMapping | Unset
        if isinstance(_identity_mapping, Unset):
            identity_mapping = UNSET
        else:
            identity_mapping = PostV1OauthProvidersByIdBodyIdentityMapping.from_dict(
                _identity_mapping
            )

        post_v1_oauth_providers_by_id_body = cls(
            slug=slug,
            display_name=display_name,
            client_id=client_id,
            client_secret=client_secret,
            scopes=scopes,
            authorize_url=authorize_url,
            token_url=token_url,
            userinfo_url=userinfo_url,
            identity_mapping=identity_mapping,
        )

        post_v1_oauth_providers_by_id_body.additional_properties = d
        return post_v1_oauth_providers_by_id_body

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
