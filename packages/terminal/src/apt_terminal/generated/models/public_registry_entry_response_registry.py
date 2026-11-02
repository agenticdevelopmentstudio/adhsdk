from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PublicRegistryEntryResponseRegistry")


@_attrs_define
class PublicRegistryEntryResponseRegistry:
    """
    Attributes:
        slug (str):
        name (str):
        bound_site_id (None | str):
    """

    slug: str
    name: str
    bound_site_id: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        bound_site_id: None | str
        bound_site_id = self.bound_site_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "boundSiteId": bound_site_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_bound_site_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        bound_site_id = _parse_bound_site_id(d.pop("boundSiteId"))

        public_registry_entry_response_registry = cls(
            slug=slug,
            name=name,
            bound_site_id=bound_site_id,
        )

        public_registry_entry_response_registry.additional_properties = d
        return public_registry_entry_response_registry

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
