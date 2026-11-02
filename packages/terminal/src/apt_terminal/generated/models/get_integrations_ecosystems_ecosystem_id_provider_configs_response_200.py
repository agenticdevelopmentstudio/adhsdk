from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.integration_provider_config import IntegrationProviderConfig


T = TypeVar("T", bound="GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200")


@_attrs_define
class GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200:
    """
    Attributes:
        configs (list[IntegrationProviderConfig]):
    """

    configs: list[IntegrationProviderConfig]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        configs = []
        for configs_item_data in self.configs:
            configs_item = configs_item_data.to_dict()
            configs.append(configs_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "configs": configs,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_provider_config import IntegrationProviderConfig

        d = dict(src_dict)
        configs = []
        _configs = d.pop("configs")
        for configs_item_data in _configs:
            configs_item = IntegrationProviderConfig.from_dict(configs_item_data)

            configs.append(configs_item)

        get_integrations_ecosystems_ecosystem_id_provider_configs_response_200 = cls(
            configs=configs,
        )

        get_integrations_ecosystems_ecosystem_id_provider_configs_response_200.additional_properties = d
        return get_integrations_ecosystems_ecosystem_id_provider_configs_response_200

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
