from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostIntegrationsProvidersProviderIdAdoptInstallationsBody")


@_attrs_define
class PostIntegrationsProvidersProviderIdAdoptInstallationsBody:
    """
    Attributes:
        ecosystem_id (str): Target ecosystem id (the caller must manage it)
        provider_config_id (str): The saved config holding the app id and private key. See above for why it cannot be
            omitted.
        service_type (str | Unset): Defaults to the provider's primary service type.
    """

    ecosystem_id: str
    provider_config_id: str
    service_type: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        provider_config_id = self.provider_config_id

        service_type = self.service_type

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystemId": ecosystem_id,
                "providerConfigId": provider_config_id,
            }
        )
        if service_type is not UNSET:
            field_dict["serviceType"] = service_type

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId")

        provider_config_id = d.pop("providerConfigId")

        service_type = d.pop("serviceType", UNSET)

        post_integrations_providers_provider_id_adopt_installations_body = cls(
            ecosystem_id=ecosystem_id,
            provider_config_id=provider_config_id,
            service_type=service_type,
        )

        post_integrations_providers_provider_id_adopt_installations_body.additional_properties = d
        return post_integrations_providers_provider_id_adopt_installations_body

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
