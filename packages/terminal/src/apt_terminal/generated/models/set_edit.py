from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="SetEdit")


@_attrs_define
class SetEdit:
    """
    Attributes:
        slug (str | Unset):
        name (str | Unset):
        description (str | Unset):
        is_default (bool | Unset):
    """

    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    is_default: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        description = self.description

        is_default = self.is_default

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if is_default is not UNSET:
            field_dict["is_default"] = is_default

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        is_default = d.pop("is_default", UNSET)

        set_edit = cls(
            slug=slug,
            name=name,
            description=description,
            is_default=is_default,
        )

        return set_edit
