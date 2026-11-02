from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_registry_entry_detail_contact_mode import PublicRegistryEntryDetailContactMode
from ..models.public_registry_entry_detail_delivery_mode import (
    PublicRegistryEntryDetailDeliveryMode,
)
from ..models.public_registry_entry_detail_provider_type import (
    PublicRegistryEntryDetailProviderType,
)

if TYPE_CHECKING:
    from ..models.public_registry_entry_detail_area_served import (
        PublicRegistryEntryDetailAreaServed,
    )
    from ..models.public_registry_entry_detail_geo_type_0 import PublicRegistryEntryDetailGeoType0
    from ..models.public_registry_entry_detail_image_urls import PublicRegistryEntryDetailImageUrls
    from ..models.public_registry_entry_detail_links_item import PublicRegistryEntryDetailLinksItem
    from ..models.public_registry_field import PublicRegistryField
    from ..models.public_registry_service import PublicRegistryService


T = TypeVar("T", bound="PublicRegistryEntryDetail")


@_attrs_define
class PublicRegistryEntryDetail:
    """
    Attributes:
        slug (str):
        display_name (str):
        summary (str):
        photo_attachment_id (None | str):
        provider_type (PublicRegistryEntryDetailProviderType):
        category (str):
        keywords (list[str]):
        location_text (str):
        country_code (str):
        region_code (str):
        geo (None | PublicRegistryEntryDetailGeoType0):
        area_served (PublicRegistryEntryDetailAreaServed):
        delivery_mode (PublicRegistryEntryDetailDeliveryMode):
        links (list[PublicRegistryEntryDetailLinksItem]):
        contact_mode (PublicRegistryEntryDetailContactMode): Never a raw email or phone — contact is DM-only.
        languages (list[str]):
        fields (list[PublicRegistryField]):
        services (list[PublicRegistryService]):
        image_urls (PublicRegistryEntryDetailImageUrls): Attachment id -> presigned GET URL, for the photo and every
            public image field. Short-lived (15 min); absent entirely when object storage is not configured.
    """

    slug: str
    display_name: str
    summary: str
    photo_attachment_id: None | str
    provider_type: PublicRegistryEntryDetailProviderType
    category: str
    keywords: list[str]
    location_text: str
    country_code: str
    region_code: str
    geo: None | PublicRegistryEntryDetailGeoType0
    area_served: PublicRegistryEntryDetailAreaServed
    delivery_mode: PublicRegistryEntryDetailDeliveryMode
    links: list[PublicRegistryEntryDetailLinksItem]
    contact_mode: PublicRegistryEntryDetailContactMode
    languages: list[str]
    fields: list[PublicRegistryField]
    services: list[PublicRegistryService]
    image_urls: PublicRegistryEntryDetailImageUrls
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.public_registry_entry_detail_geo_type_0 import (
            PublicRegistryEntryDetailGeoType0,
        )

        slug = self.slug

        display_name = self.display_name

        summary = self.summary

        photo_attachment_id: None | str
        photo_attachment_id = self.photo_attachment_id

        provider_type = self.provider_type.value

        category = self.category

        keywords = self.keywords

        location_text = self.location_text

        country_code = self.country_code

        region_code = self.region_code

        geo: dict[str, Any] | None
        if isinstance(self.geo, PublicRegistryEntryDetailGeoType0):
            geo = self.geo.to_dict()
        else:
            geo = self.geo

        area_served = self.area_served.to_dict()

        delivery_mode = self.delivery_mode.value

        links = []
        for links_item_data in self.links:
            links_item = links_item_data.to_dict()
            links.append(links_item)

        contact_mode = self.contact_mode.value

        languages = self.languages

        fields = []
        for fields_item_data in self.fields:
            fields_item = fields_item_data.to_dict()
            fields.append(fields_item)

        services = []
        for services_item_data in self.services:
            services_item = services_item_data.to_dict()
            services.append(services_item)

        image_urls = self.image_urls.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "displayName": display_name,
                "summary": summary,
                "photoAttachmentId": photo_attachment_id,
                "providerType": provider_type,
                "category": category,
                "keywords": keywords,
                "locationText": location_text,
                "countryCode": country_code,
                "regionCode": region_code,
                "geo": geo,
                "areaServed": area_served,
                "deliveryMode": delivery_mode,
                "links": links,
                "contactMode": contact_mode,
                "languages": languages,
                "fields": fields,
                "services": services,
                "imageUrls": image_urls,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_registry_entry_detail_area_served import (
            PublicRegistryEntryDetailAreaServed,
        )
        from ..models.public_registry_entry_detail_geo_type_0 import (
            PublicRegistryEntryDetailGeoType0,
        )
        from ..models.public_registry_entry_detail_image_urls import (
            PublicRegistryEntryDetailImageUrls,
        )
        from ..models.public_registry_entry_detail_links_item import (
            PublicRegistryEntryDetailLinksItem,
        )
        from ..models.public_registry_field import PublicRegistryField
        from ..models.public_registry_service import PublicRegistryService

        d = dict(src_dict)
        slug = d.pop("slug")

        display_name = d.pop("displayName")

        summary = d.pop("summary")

        def _parse_photo_attachment_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        photo_attachment_id = _parse_photo_attachment_id(d.pop("photoAttachmentId"))

        provider_type = PublicRegistryEntryDetailProviderType(d.pop("providerType"))

        category = d.pop("category")

        keywords = cast(list[str], d.pop("keywords"))

        location_text = d.pop("locationText")

        country_code = d.pop("countryCode")

        region_code = d.pop("regionCode")

        def _parse_geo(data: object) -> None | PublicRegistryEntryDetailGeoType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                geo_type_0 = PublicRegistryEntryDetailGeoType0.from_dict(data)

                return geo_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | PublicRegistryEntryDetailGeoType0, data)

        geo = _parse_geo(d.pop("geo"))

        area_served = PublicRegistryEntryDetailAreaServed.from_dict(d.pop("areaServed"))

        delivery_mode = PublicRegistryEntryDetailDeliveryMode(d.pop("deliveryMode"))

        links = []
        _links = d.pop("links")
        for links_item_data in _links:
            links_item = PublicRegistryEntryDetailLinksItem.from_dict(links_item_data)

            links.append(links_item)

        contact_mode = PublicRegistryEntryDetailContactMode(d.pop("contactMode"))

        languages = cast(list[str], d.pop("languages"))

        fields = []
        _fields = d.pop("fields")
        for fields_item_data in _fields:
            fields_item = PublicRegistryField.from_dict(fields_item_data)

            fields.append(fields_item)

        services = []
        _services = d.pop("services")
        for services_item_data in _services:
            services_item = PublicRegistryService.from_dict(services_item_data)

            services.append(services_item)

        image_urls = PublicRegistryEntryDetailImageUrls.from_dict(d.pop("imageUrls"))

        public_registry_entry_detail = cls(
            slug=slug,
            display_name=display_name,
            summary=summary,
            photo_attachment_id=photo_attachment_id,
            provider_type=provider_type,
            category=category,
            keywords=keywords,
            location_text=location_text,
            country_code=country_code,
            region_code=region_code,
            geo=geo,
            area_served=area_served,
            delivery_mode=delivery_mode,
            links=links,
            contact_mode=contact_mode,
            languages=languages,
            fields=fields,
            services=services,
            image_urls=image_urls,
        )

        public_registry_entry_detail.additional_properties = d
        return public_registry_entry_detail

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
