from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_integrations_provider_configs_body_credential_style import (
    PostV1IntegrationsProviderConfigsBodyCredentialStyle,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_provider_configs_body_endpoints import (
        PostV1IntegrationsProviderConfigsBodyEndpoints,
    )
    from ..models.post_v1_integrations_provider_configs_body_fields import (
        PostV1IntegrationsProviderConfigsBodyFields,
    )


T = TypeVar("T", bound="PostV1IntegrationsProviderConfigsBody")


@_attrs_define
class PostV1IntegrationsProviderConfigsBody:
    """
    Attributes:
        provider_id (str):
        name (str): Human-facing instance name (drives the rdid leaf)
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
        client_id (str | Unset):
        scopes (list[str] | Unset):
        auth_url (str | Unset):
        token_url (str | Unset):
        userinfo_url (str | Unset):
        validate_url (str | Unset):
        credential_style (PostV1IntegrationsProviderConfigsBodyCredentialStyle | Unset):
        endpoints (PostV1IntegrationsProviderConfigsBodyEndpoints | Unset):
        client_secret (str | Unset): Encrypted at rest; never returned
        fields (PostV1IntegrationsProviderConfigsBodyFields | Unset): api_key providers: the provider's configFields
            keyed by field key (the one secret is split into the encrypted slot).
        enabled (bool | Unset): api_key providers: false pauses the provider without deleting its secret.
    """

    provider_id: str
    name: str
    ecosystem: str
    client_id: str | Unset = UNSET
    scopes: list[str] | Unset = UNSET
    auth_url: str | Unset = UNSET
    token_url: str | Unset = UNSET
    userinfo_url: str | Unset = UNSET
    validate_url: str | Unset = UNSET
    credential_style: PostV1IntegrationsProviderConfigsBodyCredentialStyle | Unset = UNSET
    endpoints: PostV1IntegrationsProviderConfigsBodyEndpoints | Unset = UNSET
    client_secret: str | Unset = UNSET
    fields: PostV1IntegrationsProviderConfigsBodyFields | Unset = UNSET
    enabled: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        name = self.name

        ecosystem = self.ecosystem

        client_id = self.client_id

        scopes: list[str] | Unset = UNSET
        if not isinstance(self.scopes, Unset):
            scopes = self.scopes

        auth_url = self.auth_url

        token_url = self.token_url

        userinfo_url = self.userinfo_url

        validate_url = self.validate_url

        credential_style: str | Unset = UNSET
        if not isinstance(self.credential_style, Unset):
            credential_style = self.credential_style.value

        endpoints: dict[str, Any] | Unset = UNSET
        if not isinstance(self.endpoints, Unset):
            endpoints = self.endpoints.to_dict()

        client_secret = self.client_secret

        fields: dict[str, Any] | Unset = UNSET
        if not isinstance(self.fields, Unset):
            fields = self.fields.to_dict()

        enabled = self.enabled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "provider_id": provider_id,
                "name": name,
                "ecosystem": ecosystem,
            }
        )
        if client_id is not UNSET:
            field_dict["client_id"] = client_id
        if scopes is not UNSET:
            field_dict["scopes"] = scopes
        if auth_url is not UNSET:
            field_dict["auth_url"] = auth_url
        if token_url is not UNSET:
            field_dict["token_url"] = token_url
        if userinfo_url is not UNSET:
            field_dict["userinfo_url"] = userinfo_url
        if validate_url is not UNSET:
            field_dict["validate_url"] = validate_url
        if credential_style is not UNSET:
            field_dict["credential_style"] = credential_style
        if endpoints is not UNSET:
            field_dict["endpoints"] = endpoints
        if client_secret is not UNSET:
            field_dict["client_secret"] = client_secret
        if fields is not UNSET:
            field_dict["fields"] = fields
        if enabled is not UNSET:
            field_dict["enabled"] = enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_provider_configs_body_endpoints import (
            PostV1IntegrationsProviderConfigsBodyEndpoints,
        )
        from ..models.post_v1_integrations_provider_configs_body_fields import (
            PostV1IntegrationsProviderConfigsBodyFields,
        )

        d = dict(src_dict)
        provider_id = d.pop("provider_id")

        name = d.pop("name")

        ecosystem = d.pop("ecosystem")

        client_id = d.pop("client_id", UNSET)

        scopes = cast(list[str], d.pop("scopes", UNSET))

        auth_url = d.pop("auth_url", UNSET)

        token_url = d.pop("token_url", UNSET)

        userinfo_url = d.pop("userinfo_url", UNSET)

        validate_url = d.pop("validate_url", UNSET)

        _credential_style = d.pop("credential_style", UNSET)
        credential_style: PostV1IntegrationsProviderConfigsBodyCredentialStyle | Unset
        if isinstance(_credential_style, Unset):
            credential_style = UNSET
        else:
            credential_style = PostV1IntegrationsProviderConfigsBodyCredentialStyle(
                _credential_style
            )

        _endpoints = d.pop("endpoints", UNSET)
        endpoints: PostV1IntegrationsProviderConfigsBodyEndpoints | Unset
        if isinstance(_endpoints, Unset):
            endpoints = UNSET
        else:
            endpoints = PostV1IntegrationsProviderConfigsBodyEndpoints.from_dict(_endpoints)

        client_secret = d.pop("client_secret", UNSET)

        _fields = d.pop("fields", UNSET)
        fields: PostV1IntegrationsProviderConfigsBodyFields | Unset
        if isinstance(_fields, Unset):
            fields = UNSET
        else:
            fields = PostV1IntegrationsProviderConfigsBodyFields.from_dict(_fields)

        enabled = d.pop("enabled", UNSET)

        post_v1_integrations_provider_configs_body = cls(
            provider_id=provider_id,
            name=name,
            ecosystem=ecosystem,
            client_id=client_id,
            scopes=scopes,
            auth_url=auth_url,
            token_url=token_url,
            userinfo_url=userinfo_url,
            validate_url=validate_url,
            credential_style=credential_style,
            endpoints=endpoints,
            client_secret=client_secret,
            fields=fields,
            enabled=enabled,
        )

        post_v1_integrations_provider_configs_body.additional_properties = d
        return post_v1_integrations_provider_configs_body

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
