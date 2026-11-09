from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CommunitiesByIdCategoriesBody")


@_attrs_define
class PostV1CommunitiesByIdCategoriesBody:
    """
    Attributes:
        slug (str): Unique per community.
        name (str):
        description (str | Unset):
        color (str | Unset): Display color (e.g. a hex string).
        display_order (int | Unset): Sort order within the community.
    """

    slug: str
    name: str
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    display_order: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        description = self.description

        color = self.color

        display_order = self.display_order

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if display_order is not UNSET:
            field_dict["display_order"] = display_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        display_order = d.pop("display_order", UNSET)

        post_v1_communities_by_id_categories_body = cls(
            slug=slug,
            name=name,
            description=description,
            color=color,
            display_order=display_order,
        )

        post_v1_communities_by_id_categories_body.additional_properties = d
        return post_v1_communities_by_id_categories_body

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
