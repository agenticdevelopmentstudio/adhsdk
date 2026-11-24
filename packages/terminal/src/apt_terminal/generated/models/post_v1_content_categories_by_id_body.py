from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentCategoriesByIdBody")


@_attrs_define
class PostV1ContentCategoriesByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        description (str | Unset):
        color (str | Unset):
        icon (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    icon: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        color = self.color

        icon = self.icon

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if icon is not UNSET:
            field_dict["icon"] = icon
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        icon = d.pop("icon", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_categories_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            color=color,
            icon=icon,
            sort_order=sort_order,
        )

        return post_v1_content_categories_by_id_body
