from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_registry_entry_summary_delivery_mode import (
    PublicRegistryEntrySummaryDeliveryMode,
)

T = TypeVar("T", bound="PublicRegistryEntrySummary")


@_attrs_define
class PublicRegistryEntrySummary:
    """
    Attributes:
        slug (str):
        display_name (str):
        summary (str):
        category (str):
        keywords (list[str]):
        location_text (str):
        delivery_mode (PublicRegistryEntrySummaryDeliveryMode):
        photo_attachment_id (None | str): An attachment id, not a URL — look it up in the response's `imageUrls`. Null
            whenever no URL could be produced for THIS entry (no photo set, or one that is missing, unready, not owned by
            this entry, or unpresignable — including a deployment with no object store), so an id that is present always has
            a URL in the map. Render the card without a picture when it is null.
    """

    slug: str
    display_name: str
    summary: str
    category: str
    keywords: list[str]
    location_text: str
    delivery_mode: PublicRegistryEntrySummaryDeliveryMode
    photo_attachment_id: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name = self.display_name

        summary = self.summary

        category = self.category

        keywords = self.keywords

        location_text = self.location_text

        delivery_mode = self.delivery_mode.value

        photo_attachment_id: None | str
        photo_attachment_id = self.photo_attachment_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "display_name": display_name,
                "summary": summary,
                "category": category,
                "keywords": keywords,
                "location_text": location_text,
                "delivery_mode": delivery_mode,
                "photo_attachment_id": photo_attachment_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        display_name = d.pop("display_name")

        summary = d.pop("summary")

        category = d.pop("category")

        keywords = cast(list[str], d.pop("keywords"))

        location_text = d.pop("location_text")

        delivery_mode = PublicRegistryEntrySummaryDeliveryMode(d.pop("delivery_mode"))

        def _parse_photo_attachment_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        photo_attachment_id = _parse_photo_attachment_id(d.pop("photo_attachment_id"))

        public_registry_entry_summary = cls(
            slug=slug,
            display_name=display_name,
            summary=summary,
            category=category,
            keywords=keywords,
            location_text=location_text,
            delivery_mode=delivery_mode,
            photo_attachment_id=photo_attachment_id,
        )

        public_registry_entry_summary.additional_properties = d
        return public_registry_entry_summary

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
