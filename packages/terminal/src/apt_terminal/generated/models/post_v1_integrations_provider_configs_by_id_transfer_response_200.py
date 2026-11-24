from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_provider_config import IntegrationProviderConfig


T = TypeVar("T", bound="PostV1IntegrationsProviderConfigsByIdTransferResponse200")


@_attrs_define
class PostV1IntegrationsProviderConfigsByIdTransferResponse200:
    """
    Attributes:
        config (IntegrationProviderConfig):
        connections (int): LIVE connections now in the destination — not how many rows moved. A soft-deleted connection
            travels with the config (its ecosystem column is what RLS reads) but is not a working account, so counting it
            would overstate what the operator now has.
        repository_caches (int): Cached repository lists that followed those connections.
        object_ (Literal['integrations.provider_config'] | Unset):
    """

    config: IntegrationProviderConfig
    connections: int
    repository_caches: int
    object_: Literal["integrations.provider_config"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        config = self.config.to_dict()

        connections = self.connections

        repository_caches = self.repository_caches

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "config": config,
                "connections": connections,
                "repository_caches": repository_caches,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_provider_config import IntegrationProviderConfig

        d = dict(src_dict)
        config = IntegrationProviderConfig.from_dict(d.pop("config"))

        connections = d.pop("connections")

        repository_caches = d.pop("repository_caches")

        object_ = cast(Literal["integrations.provider_config"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.provider_config" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.provider_config', got '{object_}'"
            )

        post_v1_integrations_provider_configs_by_id_transfer_response_200 = cls(
            config=config,
            connections=connections,
            repository_caches=repository_caches,
            object_=object_,
        )

        post_v1_integrations_provider_configs_by_id_transfer_response_200.additional_properties = d
        return post_v1_integrations_provider_configs_by_id_transfer_response_200

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
