from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PublicRegistrySummary")


@_attrs_define
class PublicRegistrySummary:
    """
    Attributes:
        slug (str):
        name (str):
        purpose (str): One-line "what this registry is for".
        category_root (str): The industry half of <industry>.<service-type>, e.g. 'software'.
        tags (list[str]): The owner's discovery labels.
    """

    slug: str
    name: str
    purpose: str
    category_root: str
    tags: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        purpose = self.purpose

        category_root = self.category_root

        tags = self.tags

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "purpose": purpose,
                "category_root": category_root,
                "tags": tags,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        purpose = d.pop("purpose")

        category_root = d.pop("category_root")

        tags = cast(list[str], d.pop("tags"))

        public_registry_summary = cls(
            slug=slug,
            name=name,
            purpose=purpose,
            category_root=category_root,
            tags=tags,
        )

        public_registry_summary.additional_properties = d
        return public_registry_summary

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
