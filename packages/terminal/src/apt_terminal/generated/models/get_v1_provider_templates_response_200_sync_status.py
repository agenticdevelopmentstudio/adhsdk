from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.catalog_sync_run import CatalogSyncRun


T = TypeVar("T", bound="GetV1ProviderTemplatesResponse200SyncStatus")


@_attrs_define
class GetV1ProviderTemplatesResponse200SyncStatus:
    """
    Attributes:
        sources (list[CatalogSyncRun]):
    """

    sources: list[CatalogSyncRun]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sources = []
        for sources_item_data in self.sources:
            sources_item = sources_item_data.to_dict()
            sources.append(sources_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sources": sources,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.catalog_sync_run import CatalogSyncRun

        d = dict(src_dict)
        sources = []
        _sources = d.pop("sources")
        for sources_item_data in _sources:
            sources_item = CatalogSyncRun.from_dict(sources_item_data)

            sources.append(sources_item)

        get_v1_provider_templates_response_200_sync_status = cls(
            sources=sources,
        )

        get_v1_provider_templates_response_200_sync_status.additional_properties = d
        return get_v1_provider_templates_response_200_sync_status

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
