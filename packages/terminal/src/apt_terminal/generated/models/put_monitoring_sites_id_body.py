from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutMonitoringSitesIdBody")


@_attrs_define
class PutMonitoringSitesIdBody:
    """
    Attributes:
        site_group_id (str | Unset):
        name (str | Unset):
        slug (str | Unset):
        description (None | str | Unset):
        display_order (int | Unset):
    """

    site_group_id: str | Unset = UNSET
    name: str | Unset = UNSET
    slug: str | Unset = UNSET
    description: None | str | Unset = UNSET
    display_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        site_group_id = self.site_group_id

        name = self.name

        slug = self.slug

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        display_order = self.display_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if site_group_id is not UNSET:
            field_dict["siteGroupId"] = site_group_id
        if name is not UNSET:
            field_dict["name"] = name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if description is not UNSET:
            field_dict["description"] = description
        if display_order is not UNSET:
            field_dict["displayOrder"] = display_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        site_group_id = d.pop("siteGroupId", UNSET)

        name = d.pop("name", UNSET)

        slug = d.pop("slug", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        display_order = d.pop("displayOrder", UNSET)

        put_monitoring_sites_id_body = cls(
            site_group_id=site_group_id,
            name=name,
            slug=slug,
            description=description,
            display_order=display_order,
        )

        return put_monitoring_sites_id_body
