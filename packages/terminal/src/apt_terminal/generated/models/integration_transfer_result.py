from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.integration_provider_config import IntegrationProviderConfig


T = TypeVar("T", bound="IntegrationTransferResult")


@_attrs_define
class IntegrationTransferResult:
    """
    Attributes:
        config (IntegrationProviderConfig):
        connections (int): LIVE connections now in the destination — not how many rows moved. A soft-deleted connection
            travels with the config (its ecosystem column is what RLS reads) but is not a working account, so counting it
            would overstate what the operator now has.
        repository_caches (int): Cached repository lists that followed those connections.
    """

    config: IntegrationProviderConfig
    connections: int
    repository_caches: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        config = self.config.to_dict()

        connections = self.connections

        repository_caches = self.repository_caches

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "config": config,
                "connections": connections,
                "repositoryCaches": repository_caches,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_provider_config import IntegrationProviderConfig

        d = dict(src_dict)
        config = IntegrationProviderConfig.from_dict(d.pop("config"))

        connections = d.pop("connections")

        repository_caches = d.pop("repositoryCaches")

        integration_transfer_result = cls(
            config=config,
            connections=connections,
            repository_caches=repository_caches,
        )

        integration_transfer_result.additional_properties = d
        return integration_transfer_result

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
