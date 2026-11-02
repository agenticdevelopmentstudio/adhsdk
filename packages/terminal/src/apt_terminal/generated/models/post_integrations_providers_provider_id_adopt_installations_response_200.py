from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_integrations_providers_provider_id_adopt_installations_response_200_connected_item import (
        PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200ConnectedItem,
    )
    from ..models.post_integrations_providers_provider_id_adopt_installations_response_200_skipped_item import (
        PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200SkippedItem,
    )


T = TypeVar("T", bound="PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200")


@_attrs_define
class PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200:
    """
    Attributes:
        connected (list[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200ConnectedItem]):
        skipped (list[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200SkippedItem]):
    """

    connected: list[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200ConnectedItem]
    skipped: list[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200SkippedItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        connected = []
        for connected_item_data in self.connected:
            connected_item = connected_item_data.to_dict()
            connected.append(connected_item)

        skipped = []
        for skipped_item_data in self.skipped:
            skipped_item = skipped_item_data.to_dict()
            skipped.append(skipped_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "connected": connected,
                "skipped": skipped,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_integrations_providers_provider_id_adopt_installations_response_200_connected_item import (
            PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200ConnectedItem,
        )
        from ..models.post_integrations_providers_provider_id_adopt_installations_response_200_skipped_item import (
            PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200SkippedItem,
        )

        d = dict(src_dict)
        connected = []
        _connected = d.pop("connected")
        for connected_item_data in _connected:
            connected_item = PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200ConnectedItem.from_dict(
                connected_item_data
            )

            connected.append(connected_item)

        skipped = []
        _skipped = d.pop("skipped")
        for skipped_item_data in _skipped:
            skipped_item = PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200SkippedItem.from_dict(
                skipped_item_data
            )

            skipped.append(skipped_item)

        post_integrations_providers_provider_id_adopt_installations_response_200 = cls(
            connected=connected,
            skipped=skipped,
        )

        post_integrations_providers_provider_id_adopt_installations_response_200.additional_properties = d
        return post_integrations_providers_provider_id_adopt_installations_response_200

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
