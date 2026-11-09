from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1CommunitiesByIdCategoriesByCategoryIdBody")


@_attrs_define
class PostV1CommunitiesByIdCategoriesByCategoryIdBody:
    """
    Attributes:
        slug (str | Unset):
        name (str | Unset):
        description (str | Unset):
        color (str | Unset):
        display_order (int | Unset):
        is_public (bool | Unset):
        is_archived (bool | Unset): true archives (the admin "delete") — hidden from every list, discussions retained.
    """

    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    display_order: int | Unset = UNSET
    is_public: bool | Unset = UNSET
    is_archived: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        description = self.description

        color = self.color

        display_order = self.display_order

        is_public = self.is_public

        is_archived = self.is_archived

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if display_order is not UNSET:
            field_dict["display_order"] = display_order
        if is_public is not UNSET:
            field_dict["is_public"] = is_public
        if is_archived is not UNSET:
            field_dict["is_archived"] = is_archived

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        display_order = d.pop("display_order", UNSET)

        is_public = d.pop("is_public", UNSET)

        is_archived = d.pop("is_archived", UNSET)

        post_v1_communities_by_id_categories_by_category_id_body = cls(
            slug=slug,
            name=name,
            description=description,
            color=color,
            display_order=display_order,
            is_public=is_public,
            is_archived=is_archived,
        )

        post_v1_communities_by_id_categories_by_category_id_body.additional_properties = d
        return post_v1_communities_by_id_categories_by_category_id_body

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
