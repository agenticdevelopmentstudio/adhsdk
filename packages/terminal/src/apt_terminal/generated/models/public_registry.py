from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.public_registry_field_def import PublicRegistryFieldDef
    from ..models.public_registry_section import PublicRegistrySection


T = TypeVar("T", bound="PublicRegistry")


@_attrs_define
class PublicRegistry:
    """
    Attributes:
        slug (str):
        name (str):
        purpose (str): One-line "what this registry is for".
        description (str):
        category_root (str): The industry half of <industry>.<service-type>, e.g. 'software'.
        entry_term (str): What this registry calls an entry — "consultant", "coach", "shop".
        tags (list[str]): The owner's discovery labels.
        services_enabled (bool):
        bound_site_id (None | str): A fleet SITE SLUG from the frontend sites registry, when this registry is bound to a
            dedicated site; null otherwise.
        sections (list[PublicRegistrySection]):
        fields (list[PublicRegistryFieldDef]):
    """

    slug: str
    name: str
    purpose: str
    description: str
    category_root: str
    entry_term: str
    tags: list[str]
    services_enabled: bool
    bound_site_id: None | str
    sections: list[PublicRegistrySection]
    fields: list[PublicRegistryFieldDef]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        purpose = self.purpose

        description = self.description

        category_root = self.category_root

        entry_term = self.entry_term

        tags = self.tags

        services_enabled = self.services_enabled

        bound_site_id: None | str
        bound_site_id = self.bound_site_id

        sections = []
        for sections_item_data in self.sections:
            sections_item = sections_item_data.to_dict()
            sections.append(sections_item)

        fields = []
        for fields_item_data in self.fields:
            fields_item = fields_item_data.to_dict()
            fields.append(fields_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "purpose": purpose,
                "description": description,
                "category_root": category_root,
                "entry_term": entry_term,
                "tags": tags,
                "services_enabled": services_enabled,
                "bound_site_id": bound_site_id,
                "sections": sections,
                "fields": fields,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_registry_field_def import PublicRegistryFieldDef
        from ..models.public_registry_section import PublicRegistrySection

        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        purpose = d.pop("purpose")

        description = d.pop("description")

        category_root = d.pop("category_root")

        entry_term = d.pop("entry_term")

        tags = cast(list[str], d.pop("tags"))

        services_enabled = d.pop("services_enabled")

        def _parse_bound_site_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        bound_site_id = _parse_bound_site_id(d.pop("bound_site_id"))

        sections = []
        _sections = d.pop("sections")
        for sections_item_data in _sections:
            sections_item = PublicRegistrySection.from_dict(sections_item_data)

            sections.append(sections_item)

        fields = []
        _fields = d.pop("fields")
        for fields_item_data in _fields:
            fields_item = PublicRegistryFieldDef.from_dict(fields_item_data)

            fields.append(fields_item)

        public_registry = cls(
            slug=slug,
            name=name,
            purpose=purpose,
            description=description,
            category_root=category_root,
            entry_term=entry_term,
            tags=tags,
            services_enabled=services_enabled,
            bound_site_id=bound_site_id,
            sections=sections,
            fields=fields,
        )

        public_registry.additional_properties = d
        return public_registry

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
