from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_providers_by_id_test_credentials_body_fields import (
        PostV1IntegrationsProvidersByIdTestCredentialsBodyFields,
    )


T = TypeVar("T", bound="PostV1IntegrationsProvidersByIdTestCredentialsBody")


@_attrs_define
class PostV1IntegrationsProvidersByIdTestCredentialsBody:
    """
    Attributes:
        ecosystem_id (str): The ecosystem the draft is being typed into (the caller must manage it)
        client_id (str | Unset): OAuth client id, or a GitHub App id
        client_secret (str | Unset): The secret being tried — a client secret, private key, or API token
        fields (PostV1IntegrationsProvidersByIdTestCredentialsBodyFields | Unset): The provider's declared config
            fields, as on create/update
        provider_config_id (str | Unset): The saved config being edited. Its stored secret is used when the submitted
            one is blank. See above for why this cannot simply be omitted.
    """

    ecosystem_id: str
    client_id: str | Unset = UNSET
    client_secret: str | Unset = UNSET
    fields: PostV1IntegrationsProvidersByIdTestCredentialsBodyFields | Unset = UNSET
    provider_config_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        client_id = self.client_id

        client_secret = self.client_secret

        fields: dict[str, Any] | Unset = UNSET
        if not isinstance(self.fields, Unset):
            fields = self.fields.to_dict()

        provider_config_id = self.provider_config_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
            }
        )
        if client_id is not UNSET:
            field_dict["client_id"] = client_id
        if client_secret is not UNSET:
            field_dict["client_secret"] = client_secret
        if fields is not UNSET:
            field_dict["fields"] = fields
        if provider_config_id is not UNSET:
            field_dict["provider_config_id"] = provider_config_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_providers_by_id_test_credentials_body_fields import (
            PostV1IntegrationsProvidersByIdTestCredentialsBodyFields,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id")

        client_id = d.pop("client_id", UNSET)

        client_secret = d.pop("client_secret", UNSET)

        _fields = d.pop("fields", UNSET)
        fields: PostV1IntegrationsProvidersByIdTestCredentialsBodyFields | Unset
        if isinstance(_fields, Unset):
            fields = UNSET
        else:
            fields = PostV1IntegrationsProvidersByIdTestCredentialsBodyFields.from_dict(_fields)

        provider_config_id = d.pop("provider_config_id", UNSET)

        post_v1_integrations_providers_by_id_test_credentials_body = cls(
            ecosystem_id=ecosystem_id,
            client_id=client_id,
            client_secret=client_secret,
            fields=fields,
            provider_config_id=provider_config_id,
        )

        post_v1_integrations_providers_by_id_test_credentials_body.additional_properties = d
        return post_v1_integrations_providers_by_id_test_credentials_body

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
