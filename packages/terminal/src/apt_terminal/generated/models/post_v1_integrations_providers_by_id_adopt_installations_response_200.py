from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_providers_by_id_adopt_installations_response_200_connected_item import (
        PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200ConnectedItem,
    )
    from ..models.post_v1_integrations_providers_by_id_adopt_installations_response_200_skipped_item import (
        PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200SkippedItem,
    )


T = TypeVar("T", bound="PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200")


@_attrs_define
class PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200:
    """
    Attributes:
        connected (list[PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200ConnectedItem]):
        skipped (list[PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200SkippedItem]):
        object_ (Literal['adopt_installation'] | Unset):
    """

    connected: list[PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200ConnectedItem]
    skipped: list[PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200SkippedItem]
    object_: Literal["adopt_installation"] | Unset = UNSET
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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "connected": connected,
                "skipped": skipped,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_providers_by_id_adopt_installations_response_200_connected_item import (
            PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200ConnectedItem,
        )
        from ..models.post_v1_integrations_providers_by_id_adopt_installations_response_200_skipped_item import (
            PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200SkippedItem,
        )

        d = dict(src_dict)
        connected = []
        _connected = d.pop("connected")
        for connected_item_data in _connected:
            connected_item = (
                PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200ConnectedItem.from_dict(
                    connected_item_data
                )
            )

            connected.append(connected_item)

        skipped = []
        _skipped = d.pop("skipped")
        for skipped_item_data in _skipped:
            skipped_item = (
                PostV1IntegrationsProvidersByIdAdoptInstallationsResponse200SkippedItem.from_dict(
                    skipped_item_data
                )
            )

            skipped.append(skipped_item)

        object_ = cast(Literal["adopt_installation"] | Unset, d.pop("object", UNSET))
        if object_ != "adopt_installation" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'adopt_installation', got '{object_}'")

        post_v1_integrations_providers_by_id_adopt_installations_response_200 = cls(
            connected=connected,
            skipped=skipped,
            object_=object_,
        )

        post_v1_integrations_providers_by_id_adopt_installations_response_200.additional_properties = d
        return post_v1_integrations_providers_by_id_adopt_installations_response_200

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
