from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MonitoringSiteGroupsByIdBody")


@_attrs_define
class PostV1MonitoringSiteGroupsByIdBody:
    """
    Attributes:
        name (str | Unset):
        slug (str | Unset):
        description (None | str | Unset):
        retention_days (int | Unset):
        display_order (int | Unset):
    """

    name: str | Unset = UNSET
    slug: str | Unset = UNSET
    description: None | str | Unset = UNSET
    retention_days: int | Unset = UNSET
    display_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        slug = self.slug

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        retention_days = self.retention_days

        display_order = self.display_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if description is not UNSET:
            field_dict["description"] = description
        if retention_days is not UNSET:
            field_dict["retention_days"] = retention_days
        if display_order is not UNSET:
            field_dict["display_order"] = display_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        slug = d.pop("slug", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        retention_days = d.pop("retention_days", UNSET)

        display_order = d.pop("display_order", UNSET)

        post_v1_monitoring_site_groups_by_id_body = cls(
            name=name,
            slug=slug,
            description=description,
            retention_days=retention_days,
            display_order=display_order,
        )

        return post_v1_monitoring_site_groups_by_id_body
