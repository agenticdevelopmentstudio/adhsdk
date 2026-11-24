from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsProvidersByIdRegisterInstanceBodyType1")


@_attrs_define
class PostV1IntegrationsProvidersByIdRegisterInstanceBodyType1:
    """
    Attributes:
        ecosystem_id (str): Target ecosystem id (the caller must manage it)
        instance_url (str):
        redirect_uri (str):
        service_type (str | Unset):
        provider_config_id (str | Unset): When set, per-instance clientId/clientSecret/instanceUrl come from this
            ecosystem provider-config (not a dynamic registration) and the connection links it.
    """

    ecosystem_id: str
    instance_url: str
    redirect_uri: str
    service_type: str | Unset = UNSET
    provider_config_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        instance_url = self.instance_url

        redirect_uri = self.redirect_uri

        service_type = self.service_type

        provider_config_id = self.provider_config_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
                "instance_url": instance_url,
                "redirect_uri": redirect_uri,
            }
        )
        if service_type is not UNSET:
            field_dict["service_type"] = service_type
        if provider_config_id is not UNSET:
            field_dict["provider_config_id"] = provider_config_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id")

        instance_url = d.pop("instance_url")

        redirect_uri = d.pop("redirect_uri")

        service_type = d.pop("service_type", UNSET)

        provider_config_id = d.pop("provider_config_id", UNSET)

        post_v1_integrations_providers_by_id_register_instance_body_type_1 = cls(
            ecosystem_id=ecosystem_id,
            instance_url=instance_url,
            redirect_uri=redirect_uri,
            service_type=service_type,
            provider_config_id=provider_config_id,
        )

        post_v1_integrations_providers_by_id_register_instance_body_type_1.additional_properties = d
        return post_v1_integrations_providers_by_id_register_instance_body_type_1

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
