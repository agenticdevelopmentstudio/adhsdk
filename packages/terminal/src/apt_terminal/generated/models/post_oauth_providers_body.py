from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_oauth_providers_body_auth_type import PostOauthProvidersBodyAuthType
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_oauth_providers_body_identity_mapping import (
        PostOauthProvidersBodyIdentityMapping,
    )


T = TypeVar("T", bound="PostOauthProvidersBody")


@_attrs_define
class PostOauthProvidersBody:
    """
    Attributes:
        client_id (str):
        client_secret (str):
        template_slug (str | Unset):
        slug (str | Unset):
        display_name (str | Unset):
        scopes (list[str] | Unset):
        authorize_url (None | str | Unset):
        token_url (None | str | Unset):
        userinfo_url (None | str | Unset):
        auth_type (PostOauthProvidersBodyAuthType | Unset):
        identity_mapping (PostOauthProvidersBodyIdentityMapping | Unset):
    """

    client_id: str
    client_secret: str
    template_slug: str | Unset = UNSET
    slug: str | Unset = UNSET
    display_name: str | Unset = UNSET
    scopes: list[str] | Unset = UNSET
    authorize_url: None | str | Unset = UNSET
    token_url: None | str | Unset = UNSET
    userinfo_url: None | str | Unset = UNSET
    auth_type: PostOauthProvidersBodyAuthType | Unset = UNSET
    identity_mapping: PostOauthProvidersBodyIdentityMapping | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_id = self.client_id

        client_secret = self.client_secret

        template_slug = self.template_slug

        slug = self.slug

        display_name = self.display_name

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

        auth_type: str | Unset = UNSET
        if not isinstance(self.auth_type, Unset):
            auth_type = self.auth_type.value

        identity_mapping: dict[str, Any] | Unset = UNSET
        if not isinstance(self.identity_mapping, Unset):
            identity_mapping = self.identity_mapping.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "clientId": client_id,
                "clientSecret": client_secret,
            }
        )
        if template_slug is not UNSET:
            field_dict["templateSlug"] = template_slug
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if scopes is not UNSET:
            field_dict["scopes"] = scopes
        if authorize_url is not UNSET:
            field_dict["authorizeUrl"] = authorize_url
        if token_url is not UNSET:
            field_dict["tokenUrl"] = token_url
        if userinfo_url is not UNSET:
            field_dict["userinfoUrl"] = userinfo_url
        if auth_type is not UNSET:
            field_dict["authType"] = auth_type
        if identity_mapping is not UNSET:
            field_dict["identityMapping"] = identity_mapping

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_oauth_providers_body_identity_mapping import (
            PostOauthProvidersBodyIdentityMapping,
        )

        d = dict(src_dict)
        client_id = d.pop("clientId")

        client_secret = d.pop("clientSecret")

        template_slug = d.pop("templateSlug", UNSET)

        slug = d.pop("slug", UNSET)

        display_name = d.pop("displayName", UNSET)

        scopes = cast(list[str], d.pop("scopes", UNSET))

        def _parse_authorize_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        authorize_url = _parse_authorize_url(d.pop("authorizeUrl", UNSET))

        def _parse_token_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        token_url = _parse_token_url(d.pop("tokenUrl", UNSET))

        def _parse_userinfo_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        userinfo_url = _parse_userinfo_url(d.pop("userinfoUrl", UNSET))

        _auth_type = d.pop("authType", UNSET)
        auth_type: PostOauthProvidersBodyAuthType | Unset
        if isinstance(_auth_type, Unset):
            auth_type = UNSET
        else:
            auth_type = PostOauthProvidersBodyAuthType(_auth_type)

        _identity_mapping = d.pop("identityMapping", UNSET)
        identity_mapping: PostOauthProvidersBodyIdentityMapping | Unset
        if isinstance(_identity_mapping, Unset):
            identity_mapping = UNSET
        else:
            identity_mapping = PostOauthProvidersBodyIdentityMapping.from_dict(_identity_mapping)

        post_oauth_providers_body = cls(
            client_id=client_id,
            client_secret=client_secret,
            template_slug=template_slug,
            slug=slug,
            display_name=display_name,
            scopes=scopes,
            authorize_url=authorize_url,
            token_url=token_url,
            userinfo_url=userinfo_url,
            auth_type=auth_type,
            identity_mapping=identity_mapping,
        )

        post_oauth_providers_body.additional_properties = d
        return post_oauth_providers_body

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
