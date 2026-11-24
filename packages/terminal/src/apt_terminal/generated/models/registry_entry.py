from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_entry_contact_mode import RegistryEntryContactMode
from ..models.registry_entry_delivery_mode import RegistryEntryDeliveryMode
from ..models.registry_entry_owner_kind import RegistryEntryOwnerKind
from ..models.registry_entry_provider_type import RegistryEntryProviderType
from ..models.registry_entry_status import RegistryEntryStatus
from ..models.registry_entry_visibility import RegistryEntryVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.registry_entry_area_served import RegistryEntryAreaServed
    from ..models.registry_entry_geo_type_0 import RegistryEntryGeoType0
    from ..models.registry_entry_links_item import RegistryEntryLinksItem
    from ..models.registry_entry_value_visibility import RegistryEntryValueVisibility
    from ..models.registry_entry_values import RegistryEntryValues


T = TypeVar("T", bound="RegistryEntry")


@_attrs_define
class RegistryEntry:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        registry_id (str):
        owner_kind (RegistryEntryOwnerKind):
        owner_id (str):
        slug (str): unique within the registry; the public profile path segment
        display_name (str):
        summary (str):
        provider_type (RegistryEntryProviderType):
        category (str): leaf category, e.g. software.consulting
        keywords (list[str]):
        location_text (str):
        country_code (str):
        region_code (str):
        area_served (RegistryEntryAreaServed):
        delivery_mode (RegistryEntryDeliveryMode):
        links (list[RegistryEntryLinksItem]):
        contact_mode (RegistryEntryContactMode): never a raw email or phone — see the schema column comment
        languages (list[str]):
        status (RegistryEntryStatus):
        visibility (RegistryEntryVisibility):
        values (RegistryEntryValues): owner-defined tail, keyed by field_defs.key; shape-validated on every write
        value_visibility (RegistryEntryValueVisibility): the registrant's per-field audience overrides, keyed by
            field_defs.key; a key is absent when the field simply follows its def. Never wider than the def allows AS
            STORED, but read it as the tighter of the two anyway — the owner's ceiling can move after this map is written
        schema_version (int):
        search_text (str): derived on write from PUBLIC-visible values only
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        photo_attachment_id (None | str | Unset):
        geo (None | RegistryEntryGeoType0 | Unset):
        published_at (None | str | Unset):
        deleted_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    registry_id: str
    owner_kind: RegistryEntryOwnerKind
    owner_id: str
    slug: str
    display_name: str
    summary: str
    provider_type: RegistryEntryProviderType
    category: str
    keywords: list[str]
    location_text: str
    country_code: str
    region_code: str
    area_served: RegistryEntryAreaServed
    delivery_mode: RegistryEntryDeliveryMode
    links: list[RegistryEntryLinksItem]
    contact_mode: RegistryEntryContactMode
    languages: list[str]
    status: RegistryEntryStatus
    visibility: RegistryEntryVisibility
    values: RegistryEntryValues
    value_visibility: RegistryEntryValueVisibility
    schema_version: int
    search_text: str
    created: int
    updated: int
    sync_version: int
    photo_attachment_id: None | str | Unset = UNSET
    geo: None | RegistryEntryGeoType0 | Unset = UNSET
    published_at: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.registry_entry_geo_type_0 import RegistryEntryGeoType0

        id = self.id

        ecosystem_id = self.ecosystem_id

        registry_id = self.registry_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        slug = self.slug

        display_name = self.display_name

        summary = self.summary

        provider_type = self.provider_type.value

        category = self.category

        keywords = self.keywords

        location_text = self.location_text

        country_code = self.country_code

        region_code = self.region_code

        area_served = self.area_served.to_dict()

        delivery_mode = self.delivery_mode.value

        links = []
        for links_item_data in self.links:
            links_item = links_item_data.to_dict()
            links.append(links_item)

        contact_mode = self.contact_mode.value

        languages = self.languages

        status = self.status.value

        visibility = self.visibility.value

        values = self.values.to_dict()

        value_visibility = self.value_visibility.to_dict()

        schema_version = self.schema_version

        search_text = self.search_text

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        photo_attachment_id: None | str | Unset
        if isinstance(self.photo_attachment_id, Unset):
            photo_attachment_id = UNSET
        else:
            photo_attachment_id = self.photo_attachment_id

        geo: dict[str, Any] | None | Unset
        if isinstance(self.geo, Unset):
            geo = UNSET
        elif isinstance(self.geo, RegistryEntryGeoType0):
            geo = self.geo.to_dict()
        else:
            geo = self.geo

        published_at: None | str | Unset
        if isinstance(self.published_at, Unset):
            published_at = UNSET
        else:
            published_at = self.published_at

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "registry_id": registry_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "display_name": display_name,
                "summary": summary,
                "provider_type": provider_type,
                "category": category,
                "keywords": keywords,
                "location_text": location_text,
                "country_code": country_code,
                "region_code": region_code,
                "area_served": area_served,
                "delivery_mode": delivery_mode,
                "links": links,
                "contact_mode": contact_mode,
                "languages": languages,
                "status": status,
                "visibility": visibility,
                "values": values,
                "value_visibility": value_visibility,
                "schema_version": schema_version,
                "search_text": search_text,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
            }
        )
        if photo_attachment_id is not UNSET:
            field_dict["photo_attachment_id"] = photo_attachment_id
        if geo is not UNSET:
            field_dict["geo"] = geo
        if published_at is not UNSET:
            field_dict["published_at"] = published_at
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_entry_area_served import RegistryEntryAreaServed
        from ..models.registry_entry_geo_type_0 import RegistryEntryGeoType0
        from ..models.registry_entry_links_item import RegistryEntryLinksItem
        from ..models.registry_entry_value_visibility import (
            RegistryEntryValueVisibility,
        )
        from ..models.registry_entry_values import RegistryEntryValues

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        registry_id = d.pop("registry_id")

        owner_kind = RegistryEntryOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        slug = d.pop("slug")

        display_name = d.pop("display_name")

        summary = d.pop("summary")

        provider_type = RegistryEntryProviderType(d.pop("provider_type"))

        category = d.pop("category")

        keywords = cast(list[str], d.pop("keywords"))

        location_text = d.pop("location_text")

        country_code = d.pop("country_code")

        region_code = d.pop("region_code")

        area_served = RegistryEntryAreaServed.from_dict(d.pop("area_served"))

        delivery_mode = RegistryEntryDeliveryMode(d.pop("delivery_mode"))

        links = []
        _links = d.pop("links")
        for links_item_data in _links:
            links_item = RegistryEntryLinksItem.from_dict(links_item_data)

            links.append(links_item)

        contact_mode = RegistryEntryContactMode(d.pop("contact_mode"))

        languages = cast(list[str], d.pop("languages"))

        status = RegistryEntryStatus(d.pop("status"))

        visibility = RegistryEntryVisibility(d.pop("visibility"))

        values = RegistryEntryValues.from_dict(d.pop("values"))

        value_visibility = RegistryEntryValueVisibility.from_dict(d.pop("value_visibility"))

        schema_version = d.pop("schema_version")

        search_text = d.pop("search_text")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_photo_attachment_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        photo_attachment_id = _parse_photo_attachment_id(d.pop("photo_attachment_id", UNSET))

        def _parse_geo(data: object) -> None | RegistryEntryGeoType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                geo_type_0 = RegistryEntryGeoType0.from_dict(data)

                return geo_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | RegistryEntryGeoType0 | Unset, data)

        geo = _parse_geo(d.pop("geo", UNSET))

        def _parse_published_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        published_at = _parse_published_at(d.pop("published_at", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        registry_entry = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            registry_id=registry_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            display_name=display_name,
            summary=summary,
            provider_type=provider_type,
            category=category,
            keywords=keywords,
            location_text=location_text,
            country_code=country_code,
            region_code=region_code,
            area_served=area_served,
            delivery_mode=delivery_mode,
            links=links,
            contact_mode=contact_mode,
            languages=languages,
            status=status,
            visibility=visibility,
            values=values,
            value_visibility=value_visibility,
            schema_version=schema_version,
            search_text=search_text,
            created=created,
            updated=updated,
            sync_version=sync_version,
            photo_attachment_id=photo_attachment_id,
            geo=geo,
            published_at=published_at,
            deleted_at=deleted_at,
        )

        registry_entry.additional_properties = d
        return registry_entry

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
