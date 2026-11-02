from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.public_registry_entry_list_image_urls import PublicRegistryEntryListImageUrls
    from ..models.public_registry_entry_summary import PublicRegistryEntrySummary


T = TypeVar("T", bound="PublicRegistryEntryList")


@_attrs_define
class PublicRegistryEntryList:
    """
    Attributes:
        items (list[PublicRegistryEntrySummary]):
        total (int):
        page (int):
        page_size (int):
        image_urls (PublicRegistryEntryListImageUrls): Attachment id -> presigned GET URL, for the photos on THIS page.
            One map per page rather than a URL per item: two entries may not share a photo, but one map keyed by id matches
            the entry-detail shape and costs nothing to look up. Short-lived (15 min), and empty when object storage is not
            configured.
    """

    items: list[PublicRegistryEntrySummary]
    total: int
    page: int
    page_size: int
    image_urls: PublicRegistryEntryListImageUrls
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        total = self.total

        page = self.page

        page_size = self.page_size

        image_urls = self.image_urls.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "items": items,
                "total": total,
                "page": page,
                "pageSize": page_size,
                "imageUrls": image_urls,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_registry_entry_list_image_urls import (
            PublicRegistryEntryListImageUrls,
        )
        from ..models.public_registry_entry_summary import (
            PublicRegistryEntrySummary,
        )

        d = dict(src_dict)
        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = PublicRegistryEntrySummary.from_dict(items_item_data)

            items.append(items_item)

        total = d.pop("total")

        page = d.pop("page")

        page_size = d.pop("pageSize")

        image_urls = PublicRegistryEntryListImageUrls.from_dict(d.pop("imageUrls"))

        public_registry_entry_list = cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            image_urls=image_urls,
        )

        public_registry_entry_list.additional_properties = d
        return public_registry_entry_list

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
