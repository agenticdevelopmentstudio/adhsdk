from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_registry_registries_registry_id_entries_body_contact_mode import (
    PostRegistryRegistriesRegistryIdEntriesBodyContactMode,
)
from ..models.post_registry_registries_registry_id_entries_body_delivery_mode import (
    PostRegistryRegistriesRegistryIdEntriesBodyDeliveryMode,
)
from ..models.post_registry_registries_registry_id_entries_body_provider_type import (
    PostRegistryRegistriesRegistryIdEntriesBodyProviderType,
)
from ..models.post_registry_registries_registry_id_entries_body_status import (
    PostRegistryRegistriesRegistryIdEntriesBodyStatus,
)
from ..models.post_registry_registries_registry_id_entries_body_visibility import (
    PostRegistryRegistriesRegistryIdEntriesBodyVisibility,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_registry_registries_registry_id_entries_body_area_served import (
        PostRegistryRegistriesRegistryIdEntriesBodyAreaServed,
    )
    from ..models.post_registry_registries_registry_id_entries_body_geo_type_0 import (
        PostRegistryRegistriesRegistryIdEntriesBodyGeoType0,
    )
    from ..models.post_registry_registries_registry_id_entries_body_links_item import (
        PostRegistryRegistriesRegistryIdEntriesBodyLinksItem,
    )
    from ..models.post_registry_registries_registry_id_entries_body_value_visibility import (
        PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility,
    )
    from ..models.post_registry_registries_registry_id_entries_body_values import (
        PostRegistryRegistriesRegistryIdEntriesBodyValues,
    )


T = TypeVar("T", bound="PostRegistryRegistriesRegistryIdEntriesBody")


@_attrs_define
class PostRegistryRegistriesRegistryIdEntriesBody:
    """
    Attributes:
        slug (str | Unset):
        display_name (str | Unset):
        summary (str | Unset):
        photo_attachment_id (None | str | Unset):
        provider_type (PostRegistryRegistriesRegistryIdEntriesBodyProviderType | Unset):
        category (str | Unset):
        keywords (list[str] | Unset):
        location_text (str | Unset):
        country_code (str | Unset):
        region_code (str | Unset):
        geo (None | PostRegistryRegistriesRegistryIdEntriesBodyGeoType0 | Unset):
        area_served (PostRegistryRegistriesRegistryIdEntriesBodyAreaServed | Unset):
        delivery_mode (PostRegistryRegistriesRegistryIdEntriesBodyDeliveryMode | Unset):
        links (list[PostRegistryRegistriesRegistryIdEntriesBodyLinksItem] | Unset):
        contact_mode (PostRegistryRegistriesRegistryIdEntriesBodyContactMode | Unset):
        languages (list[str] | Unset):
        status (PostRegistryRegistriesRegistryIdEntriesBodyStatus | Unset):
        visibility (PostRegistryRegistriesRegistryIdEntriesBodyVisibility | Unset):
        values (PostRegistryRegistriesRegistryIdEntriesBodyValues | Unset): shape-checked against the live field defs on
            every write; required-ness only enforced when the resulting status is (or stays) published. On PATCH this is a
            JSON Merge Patch (RFC 7386) applied to the STORED values, not a full replace: a key you omit is left untouched;
            a key you send with a non-null value replaces that one field; a key you send as null DELETES it. Send only the
            section you are editing — the rest of the entry is preserved. On POST there is no prior state, so this object IS
            the initial values as given (null has no special meaning here).
        value_visibility (PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility | Unset): The registrant's per-
            field audience overrides on THIS entry, keyed by field_defs.key. Merge-patch like `values`: a key you omit keeps
            its stored setting, a key sent as null clears the override back to the def's setting. Each override may only
            TIGHTEN the owner's ceiling (RegistryFieldDef.visibility); asking for a WIDER one is a 400 naming the field,
            never a silent clamp — a 200 would leave the registrant believing they published a field the owner keeps
            private. A stored override the owner has since tightened past is clamped and written back without erroring,
            since it was already clamped on every read.
    """

    slug: str | Unset = UNSET
    display_name: str | Unset = UNSET
    summary: str | Unset = UNSET
    photo_attachment_id: None | str | Unset = UNSET
    provider_type: PostRegistryRegistriesRegistryIdEntriesBodyProviderType | Unset = UNSET
    category: str | Unset = UNSET
    keywords: list[str] | Unset = UNSET
    location_text: str | Unset = UNSET
    country_code: str | Unset = UNSET
    region_code: str | Unset = UNSET
    geo: None | PostRegistryRegistriesRegistryIdEntriesBodyGeoType0 | Unset = UNSET
    area_served: PostRegistryRegistriesRegistryIdEntriesBodyAreaServed | Unset = UNSET
    delivery_mode: PostRegistryRegistriesRegistryIdEntriesBodyDeliveryMode | Unset = UNSET
    links: list[PostRegistryRegistriesRegistryIdEntriesBodyLinksItem] | Unset = UNSET
    contact_mode: PostRegistryRegistriesRegistryIdEntriesBodyContactMode | Unset = UNSET
    languages: list[str] | Unset = UNSET
    status: PostRegistryRegistriesRegistryIdEntriesBodyStatus | Unset = UNSET
    visibility: PostRegistryRegistriesRegistryIdEntriesBodyVisibility | Unset = UNSET
    values: PostRegistryRegistriesRegistryIdEntriesBodyValues | Unset = UNSET
    value_visibility: PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_registry_registries_registry_id_entries_body_geo_type_0 import (
            PostRegistryRegistriesRegistryIdEntriesBodyGeoType0,
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
        elif isinstance(self.geo, PostRegistryRegistriesRegistryIdEntriesBodyGeoType0):
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
        from ..models.post_registry_registries_registry_id_entries_body_area_served import (
            PostRegistryRegistriesRegistryIdEntriesBodyAreaServed,
        )
        from ..models.post_registry_registries_registry_id_entries_body_geo_type_0 import (
            PostRegistryRegistriesRegistryIdEntriesBodyGeoType0,
        )
        from ..models.post_registry_registries_registry_id_entries_body_links_item import (
            PostRegistryRegistriesRegistryIdEntriesBodyLinksItem,
        )
        from ..models.post_registry_registries_registry_id_entries_body_value_visibility import (
            PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility,
        )
        from ..models.post_registry_registries_registry_id_entries_body_values import (
            PostRegistryRegistriesRegistryIdEntriesBodyValues,
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
        provider_type: PostRegistryRegistriesRegistryIdEntriesBodyProviderType | Unset
        if isinstance(_provider_type, Unset):
            provider_type = UNSET
        else:
            provider_type = PostRegistryRegistriesRegistryIdEntriesBodyProviderType(_provider_type)

        category = d.pop("category", UNSET)

        keywords = cast(list[str], d.pop("keywords", UNSET))

        location_text = d.pop("locationText", UNSET)

        country_code = d.pop("countryCode", UNSET)

        region_code = d.pop("regionCode", UNSET)

        def _parse_geo(
            data: object,
        ) -> None | PostRegistryRegistriesRegistryIdEntriesBodyGeoType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                geo_type_0 = PostRegistryRegistriesRegistryIdEntriesBodyGeoType0.from_dict(data)

                return geo_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | PostRegistryRegistriesRegistryIdEntriesBodyGeoType0 | Unset, data)

        geo = _parse_geo(d.pop("geo", UNSET))

        _area_served = d.pop("areaServed", UNSET)
        area_served: PostRegistryRegistriesRegistryIdEntriesBodyAreaServed | Unset
        if isinstance(_area_served, Unset):
            area_served = UNSET
        else:
            area_served = PostRegistryRegistriesRegistryIdEntriesBodyAreaServed.from_dict(
                _area_served
            )

        _delivery_mode = d.pop("deliveryMode", UNSET)
        delivery_mode: PostRegistryRegistriesRegistryIdEntriesBodyDeliveryMode | Unset
        if isinstance(_delivery_mode, Unset):
            delivery_mode = UNSET
        else:
            delivery_mode = PostRegistryRegistriesRegistryIdEntriesBodyDeliveryMode(_delivery_mode)

        _links = d.pop("links", UNSET)
        links: list[PostRegistryRegistriesRegistryIdEntriesBodyLinksItem] | Unset = UNSET
        if _links is not UNSET:
            links = []
            for links_item_data in _links:
                links_item = PostRegistryRegistriesRegistryIdEntriesBodyLinksItem.from_dict(
                    links_item_data
                )

                links.append(links_item)

        _contact_mode = d.pop("contactMode", UNSET)
        contact_mode: PostRegistryRegistriesRegistryIdEntriesBodyContactMode | Unset
        if isinstance(_contact_mode, Unset):
            contact_mode = UNSET
        else:
            contact_mode = PostRegistryRegistriesRegistryIdEntriesBodyContactMode(_contact_mode)

        languages = cast(list[str], d.pop("languages", UNSET))

        _status = d.pop("status", UNSET)
        status: PostRegistryRegistriesRegistryIdEntriesBodyStatus | Unset
        if isinstance(_status, Unset):
            status = UNSET
        else:
            status = PostRegistryRegistriesRegistryIdEntriesBodyStatus(_status)

        _visibility = d.pop("visibility", UNSET)
        visibility: PostRegistryRegistriesRegistryIdEntriesBodyVisibility | Unset
        if isinstance(_visibility, Unset):
            visibility = UNSET
        else:
            visibility = PostRegistryRegistriesRegistryIdEntriesBodyVisibility(_visibility)

        _values = d.pop("values", UNSET)
        values: PostRegistryRegistriesRegistryIdEntriesBodyValues | Unset
        if isinstance(_values, Unset):
            values = UNSET
        else:
            values = PostRegistryRegistriesRegistryIdEntriesBodyValues.from_dict(_values)

        _value_visibility = d.pop("valueVisibility", UNSET)
        value_visibility: PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility | Unset
        if isinstance(_value_visibility, Unset):
            value_visibility = UNSET
        else:
            value_visibility = PostRegistryRegistriesRegistryIdEntriesBodyValueVisibility.from_dict(
                _value_visibility
            )

        post_registry_registries_registry_id_entries_body = cls(
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

        post_registry_registries_registry_id_entries_body.additional_properties = d
        return post_registry_registries_registry_id_entries_body

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
