from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_oauth_providers_by_id_response_200_auth_type import (
    GetV1OauthProvidersByIdResponse200AuthType,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_oauth_providers_by_id_response_200_identity_mapping import (
        GetV1OauthProvidersByIdResponse200IdentityMapping,
    )


T = TypeVar("T", bound="GetV1OauthProvidersByIdResponse200")


@_attrs_define
class GetV1OauthProvidersByIdResponse200:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        auth_type (GetV1OauthProvidersByIdResponse200AuthType):
        client_id (str):
        scopes (list[str]):
        identity_mapping (GetV1OauthProvidersByIdResponse200IdentityMapping):
        object_ (Literal['oauth.provider'] | Unset):
        authorize_url (None | str | Unset):
        token_url (None | str | Unset):
        userinfo_url (None | str | Unset):
    """

    id: str
    slug: str
    name: str
    auth_type: GetV1OauthProvidersByIdResponse200AuthType
    client_id: str
    scopes: list[str]
    identity_mapping: GetV1OauthProvidersByIdResponse200IdentityMapping
    object_: Literal["oauth.provider"] | Unset = UNSET
    authorize_url: None | str | Unset = UNSET
    token_url: None | str | Unset = UNSET
    userinfo_url: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        auth_type = self.auth_type.value

        client_id = self.client_id

        scopes = self.scopes

        identity_mapping = self.identity_mapping.to_dict()

        object_ = self.object_

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

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "auth_type": auth_type,
                "client_id": client_id,
                "scopes": scopes,
                "identity_mapping": identity_mapping,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if authorize_url is not UNSET:
            field_dict["authorize_url"] = authorize_url
        if token_url is not UNSET:
            field_dict["token_url"] = token_url
        if userinfo_url is not UNSET:
            field_dict["userinfo_url"] = userinfo_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_oauth_providers_by_id_response_200_identity_mapping import (
            GetV1OauthProvidersByIdResponse200IdentityMapping,
        )

        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        auth_type = GetV1OauthProvidersByIdResponse200AuthType(d.pop("auth_type"))

        client_id = d.pop("client_id")

        scopes = cast(list[str], d.pop("scopes"))

        identity_mapping = GetV1OauthProvidersByIdResponse200IdentityMapping.from_dict(
            d.pop("identity_mapping")
        )

        object_ = cast(Literal["oauth.provider"] | Unset, d.pop("object", UNSET))
        if object_ != "oauth.provider" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'oauth.provider', got '{object_}'")

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

        get_v1_oauth_providers_by_id_response_200 = cls(
            id=id,
            slug=slug,
            name=name,
            auth_type=auth_type,
            client_id=client_id,
            scopes=scopes,
            identity_mapping=identity_mapping,
            object_=object_,
            authorize_url=authorize_url,
            token_url=token_url,
            userinfo_url=userinfo_url,
        )

        get_v1_oauth_providers_by_id_response_200.additional_properties = d
        return get_v1_oauth_providers_by_id_response_200

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
