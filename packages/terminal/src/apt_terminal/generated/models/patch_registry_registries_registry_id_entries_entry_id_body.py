from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_registry_registries_registry_id_entries_entry_id_body_contact_mode import (
    PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode,
)
from ..models.patch_registry_registries_registry_id_entries_entry_id_body_delivery_mode import (
    PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyDeliveryMode,
)
from ..models.patch_registry_registries_registry_id_entries_entry_id_body_provider_type import (
    PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType,
)
from ..models.patch_registry_registries_registry_id_entries_entry_id_body_status import (
    PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyStatus,
)
from ..models.patch_registry_registries_registry_id_entries_entry_id_body_visibility import (
    PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyVisibility,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.patch_registry_registries_registry_id_entries_entry_id_body_area_served import (
        PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed,
    )
    from ..models.patch_registry_registries_registry_id_entries_entry_id_body_geo_type_0 import (
        PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0,
    )
    from ..models.patch_registry_registries_registry_id_entries_entry_id_body_links_item import (
        PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem,
    )
    from ..models.patch_registry_registries_registry_id_entries_entry_id_body_value_visibility import (
        PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility,
    )
    from ..models.patch_registry_registries_registry_id_entries_entry_id_body_values import (
        PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues,
    )


T = TypeVar("T", bound="PatchRegistryRegistriesRegistryIdEntriesEntryIdBody")


@_attrs_define
class PatchRegistryRegistriesRegistryIdEntriesEntryIdBody:
    """
    Attributes:
        slug (str | Unset):
        display_name (str | Unset):
        summary (str | Unset):
        photo_attachment_id (None | str | Unset):
        provider_type (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType | Unset):
        category (str | Unset):
        keywords (list[str] | Unset):
        location_text (str | Unset):
        country_code (str | Unset):
        region_code (str | Unset):
        geo (None | PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0 | Unset):
        area_served (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed | Unset):
        delivery_mode (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyDeliveryMode | Unset):
        links (list[PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem] | Unset):
        contact_mode (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode | Unset):
        languages (list[str] | Unset):
        status (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyStatus | Unset):
        visibility (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyVisibility | Unset):
        values (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues | Unset): shape-checked against the live field
            defs on every write; required-ness only enforced when the resulting status is (or stays) published. On PATCH
            this is a JSON Merge Patch (RFC 7386) applied to the STORED values, not a full replace: a key you omit is left
            untouched; a key you send with a non-null value replaces that one field; a key you send as null DELETES it. Send
            only the section you are editing — the rest of the entry is preserved. On POST there is no prior state, so this
            object IS the initial values as given (null has no special meaning here).
        value_visibility (PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility | Unset): The registrant's
            per-field audience overrides on THIS entry, keyed by field_defs.key. Merge-patch like `values`: a key you omit
            keeps its stored setting, a key sent as null clears the override back to the def's setting. Each override may
            only TIGHTEN the owner's ceiling (RegistryFieldDef.visibility); asking for a WIDER one is a 400 naming the
            field, never a silent clamp — a 200 would leave the registrant believing they published a field the owner keeps
            private. A stored override the owner has since tightened past is clamped and written back without erroring,
            since it was already clamped on every read.
    """

    slug: str | Unset = UNSET
    display_name: str | Unset = UNSET
    summary: str | Unset = UNSET
    photo_attachment_id: None | str | Unset = UNSET
    provider_type: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType | Unset = UNSET
    category: str | Unset = UNSET
    keywords: list[str] | Unset = UNSET
    location_text: str | Unset = UNSET
    country_code: str | Unset = UNSET
    region_code: str | Unset = UNSET
    geo: None | PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0 | Unset = UNSET
    area_served: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed | Unset = UNSET
    delivery_mode: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyDeliveryMode | Unset = UNSET
    links: list[PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem] | Unset = UNSET
    contact_mode: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode | Unset = UNSET
    languages: list[str] | Unset = UNSET
    status: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyStatus | Unset = UNSET
    visibility: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyVisibility | Unset = UNSET
    values: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues | Unset = UNSET
    value_visibility: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility | Unset = (
        UNSET
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_geo_type_0 import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0,
        )

        slug = self.slug

        display_name = self.display_name

        summary = self.summary

        photo_attachment_id: None | str | Unset
        if isinstance(self.photo_attachment_id, Unset):
            photo_attachment_id = UNSET
        else:
            photo_attachment_id = self.photo_attachment_id

        provider_type: str | Unset = UNSET
        if not isinstance(self.provider_type, Unset):
            provider_type = self.provider_type.value

        category = self.category

        keywords: list[str] | Unset = UNSET
        if not isinstance(self.keywords, Unset):
            keywords = self.keywords

        location_text = self.location_text

        country_code = self.country_code

        region_code = self.region_code

        geo: dict[str, Any] | None | Unset
        if isinstance(self.geo, Unset):
            geo = UNSET
        elif isinstance(self.geo, PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0):
            geo = self.geo.to_dict()
        else:
            geo = self.geo

        area_served: dict[str, Any] | Unset = UNSET
        if not isinstance(self.area_served, Unset):
            area_served = self.area_served.to_dict()

        delivery_mode: str | Unset = UNSET
        if not isinstance(self.delivery_mode, Unset):
            delivery_mode = self.delivery_mode.value

        links: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.links, Unset):
            links = []
            for links_item_data in self.links:
                links_item = links_item_data.to_dict()
                links.append(links_item)

        contact_mode: str | Unset = UNSET
        if not isinstance(self.contact_mode, Unset):
            contact_mode = self.contact_mode.value

        languages: list[str] | Unset = UNSET
        if not isinstance(self.languages, Unset):
            languages = self.languages

        status: str | Unset = UNSET
        if not isinstance(self.status, Unset):
            status = self.status.value

        visibility: str | Unset = UNSET
        if not isinstance(self.visibility, Unset):
            visibility = self.visibility.value

        values: dict[str, Any] | Unset = UNSET
        if not isinstance(self.values, Unset):
            values = self.values.to_dict()

        value_visibility: dict[str, Any] | Unset = UNSET
        if not isinstance(self.value_visibility, Unset):
            value_visibility = self.value_visibility.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if summary is not UNSET:
            field_dict["summary"] = summary
        if photo_attachment_id is not UNSET:
            field_dict["photoAttachmentId"] = photo_attachment_id
        if provider_type is not UNSET:
            field_dict["providerType"] = provider_type
        if category is not UNSET:
            field_dict["category"] = category
        if keywords is not UNSET:
            field_dict["keywords"] = keywords
        if location_text is not UNSET:
            field_dict["locationText"] = location_text
        if country_code is not UNSET:
            field_dict["countryCode"] = country_code
        if region_code is not UNSET:
            field_dict["regionCode"] = region_code
        if geo is not UNSET:
            field_dict["geo"] = geo
        if area_served is not UNSET:
            field_dict["areaServed"] = area_served
        if delivery_mode is not UNSET:
            field_dict["deliveryMode"] = delivery_mode
        if links is not UNSET:
            field_dict["links"] = links
        if contact_mode is not UNSET:
            field_dict["contactMode"] = contact_mode
        if languages is not UNSET:
            field_dict["languages"] = languages
        if status is not UNSET:
            field_dict["status"] = status
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if values is not UNSET:
            field_dict["values"] = values
        if value_visibility is not UNSET:
            field_dict["valueVisibility"] = value_visibility

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_area_served import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed,
        )
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_geo_type_0 import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0,
        )
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_links_item import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem,
        )
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_value_visibility import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility,
        )
        from ..models.patch_registry_registries_registry_id_entries_entry_id_body_values import (
            PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues,
        )

        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        display_name = d.pop("displayName", UNSET)

        summary = d.pop("summary", UNSET)

        def _parse_photo_attachment_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        photo_attachment_id = _parse_photo_attachment_id(d.pop("photoAttachmentId", UNSET))

        _provider_type = d.pop("providerType", UNSET)
        provider_type: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType | Unset
        if isinstance(_provider_type, Unset):
            provider_type = UNSET
        else:
            provider_type = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType(
                _provider_type
            )

        category = d.pop("category", UNSET)

        keywords = cast(list[str], d.pop("keywords", UNSET))

        location_text = d.pop("locationText", UNSET)

        country_code = d.pop("countryCode", UNSET)

        region_code = d.pop("regionCode", UNSET)

        def _parse_geo(
            data: object,
        ) -> None | PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                geo_type_0 = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0.from_dict(
                    data
                )

                return geo_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                None | PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyGeoType0 | Unset, data
            )

        geo = _parse_geo(d.pop("geo", UNSET))

        _area_served = d.pop("areaServed", UNSET)
        area_served: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed | Unset
        if isinstance(_area_served, Unset):
            area_served = UNSET
        else:
            area_served = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyAreaServed.from_dict(
                _area_served
            )

        _delivery_mode = d.pop("deliveryMode", UNSET)
        delivery_mode: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyDeliveryMode | Unset
        if isinstance(_delivery_mode, Unset):
            delivery_mode = UNSET
        else:
            delivery_mode = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyDeliveryMode(
                _delivery_mode
            )

        _links = d.pop("links", UNSET)
        links: list[PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem] | Unset = UNSET
        if _links is not UNSET:
            links = []
            for links_item_data in _links:
                links_item = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyLinksItem.from_dict(
                    links_item_data
                )

                links.append(links_item)

        _contact_mode = d.pop("contactMode", UNSET)
        contact_mode: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode | Unset
        if isinstance(_contact_mode, Unset):
            contact_mode = UNSET
        else:
            contact_mode = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode(
                _contact_mode
            )

        languages = cast(list[str], d.pop("languages", UNSET))

        _status = d.pop("status", UNSET)
        status: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyStatus | Unset
        if isinstance(_status, Unset):
            status = UNSET
        else:
            status = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyStatus(_status)

        _visibility = d.pop("visibility", UNSET)
        visibility: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyVisibility | Unset
        if isinstance(_visibility, Unset):
            visibility = UNSET
        else:
            visibility = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyVisibility(_visibility)

        _values = d.pop("values", UNSET)
        values: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues | Unset
        if isinstance(_values, Unset):
            values = UNSET
        else:
            values = PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValues.from_dict(_values)

        _value_visibility = d.pop("valueVisibility", UNSET)
        value_visibility: PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility | Unset
        if isinstance(_value_visibility, Unset):
            value_visibility = UNSET
        else:
            value_visibility = (
                PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyValueVisibility.from_dict(
                    _value_visibility
                )
            )

        patch_registry_registries_registry_id_entries_entry_id_body = cls(
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
            status=status,
            visibility=visibility,
            values=values,
            value_visibility=value_visibility,
        )

        patch_registry_registries_registry_id_entries_entry_id_body.additional_properties = d
        return patch_registry_registries_registry_id_entries_entry_id_body

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
