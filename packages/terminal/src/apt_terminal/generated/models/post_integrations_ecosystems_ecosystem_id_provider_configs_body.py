from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_integrations_ecosystems_ecosystem_id_provider_configs_body_credential_style import (
    PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyCredentialStyle,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_integrations_ecosystems_ecosystem_id_provider_configs_body_endpoints import (
        PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints,
    )
    from ..models.post_integrations_ecosystems_ecosystem_id_provider_configs_body_fields import (
        PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields,
    )


T = TypeVar("T", bound="PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody")


@_attrs_define
class PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody:
    """`providerId` + `name` identify the new instance; the remaining keys are the provider-specific config, validated by
    auth method.

        Attributes:
            provider_id (str):
            name (str): Human-facing instance name (drives the rdid leaf)
            client_id (str | Unset):
            scopes (list[str] | Unset):
            auth_url (str | Unset):
            token_url (str | Unset):
            userinfo_url (str | Unset):
            validate_url (str | Unset):
            credential_style (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyCredentialStyle | Unset):
            endpoints (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints | Unset):
            client_secret (str | Unset): Encrypted at rest; never returned
            fields (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields | Unset): api_key providers: the
                provider's configFields keyed by field key (the one secret is split into the encrypted slot).
            enabled (bool | Unset): api_key providers: false pauses the provider without deleting its secret.
    """

    provider_id: str
    name: str
    client_id: str | Unset = UNSET
    scopes: list[str] | Unset = UNSET
    auth_url: str | Unset = UNSET
    token_url: str | Unset = UNSET
    userinfo_url: str | Unset = UNSET
    validate_url: str | Unset = UNSET
    credential_style: (
        PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyCredentialStyle | Unset
    ) = UNSET
    endpoints: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints | Unset = UNSET
    client_secret: str | Unset = UNSET
    fields: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields | Unset = UNSET
    enabled: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        name = self.name

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
                "providerId": provider_id,
                "name": name,
            }
        )
        if client_id is not UNSET:
            field_dict["clientId"] = client_id
        if scopes is not UNSET:
            field_dict["scopes"] = scopes
        if auth_url is not UNSET:
            field_dict["authUrl"] = auth_url
        if token_url is not UNSET:
            field_dict["tokenUrl"] = token_url
        if userinfo_url is not UNSET:
            field_dict["userinfoUrl"] = userinfo_url
        if validate_url is not UNSET:
            field_dict["validateUrl"] = validate_url
        if credential_style is not UNSET:
            field_dict["credentialStyle"] = credential_style
        if endpoints is not UNSET:
            field_dict["endpoints"] = endpoints
        if client_secret is not UNSET:
            field_dict["clientSecret"] = client_secret
        if fields is not UNSET:
            field_dict["fields"] = fields
        if enabled is not UNSET:
            field_dict["enabled"] = enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_integrations_ecosystems_ecosystem_id_provider_configs_body_endpoints import (
            PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints,
        )
        from ..models.post_integrations_ecosystems_ecosystem_id_provider_configs_body_fields import (
            PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields,
        )

        d = dict(src_dict)
        provider_id = d.pop("providerId")

        name = d.pop("name")

        client_id = d.pop("clientId", UNSET)

        scopes = cast(list[str], d.pop("scopes", UNSET))

        auth_url = d.pop("authUrl", UNSET)

        token_url = d.pop("tokenUrl", UNSET)

        userinfo_url = d.pop("userinfoUrl", UNSET)

        validate_url = d.pop("validateUrl", UNSET)

        _credential_style = d.pop("credentialStyle", UNSET)
        credential_style: (
            PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyCredentialStyle | Unset
        )
        if isinstance(_credential_style, Unset):
            credential_style = UNSET
        else:
            credential_style = (
                PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyCredentialStyle(
                    _credential_style
                )
            )

        _endpoints = d.pop("endpoints", UNSET)
        endpoints: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints | Unset
        if isinstance(_endpoints, Unset):
            endpoints = UNSET
        else:
            endpoints = PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyEndpoints.from_dict(
                _endpoints
            )

        client_secret = d.pop("clientSecret", UNSET)

        _fields = d.pop("fields", UNSET)
        fields: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields | Unset
        if isinstance(_fields, Unset):
            fields = UNSET
        else:
            fields = PostIntegrationsEcosystemsEcosystemIdProviderConfigsBodyFields.from_dict(
                _fields
            )

        enabled = d.pop("enabled", UNSET)

        post_integrations_ecosystems_ecosystem_id_provider_configs_body = cls(
            provider_id=provider_id,
            name=name,
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

        post_integrations_ecosystems_ecosystem_id_provider_configs_body.additional_properties = d
        return post_integrations_ecosystems_ecosystem_id_provider_configs_body

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
