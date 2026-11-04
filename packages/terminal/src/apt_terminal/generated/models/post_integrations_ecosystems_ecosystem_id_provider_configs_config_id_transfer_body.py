from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdTransferBody")


@_attrs_define
class PostIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdTransferBody:
    """
    Attributes:
        target_ecosystem_id (str): Destination ecosystem — a uuid, an rdid or a slug, like any other here
    """

    target_ecosystem_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        target_ecosystem_id = self.target_ecosystem_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "targetEcosystemId": target_ecosystem_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        target_ecosystem_id = d.pop("targetEcosystemId")

        post_integrations_ecosystems_ecosystem_id_provider_configs_config_id_transfer_body = cls(
            target_ecosystem_id=target_ecosystem_id,
        )

        post_integrations_ecosystems_ecosystem_id_provider_configs_config_id_transfer_body.additional_properties = d
        return post_integrations_ecosystems_ecosystem_id_provider_configs_config_id_transfer_body

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
