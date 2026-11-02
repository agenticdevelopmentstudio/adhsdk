from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutMonitoringSitesIdResponse200")


@_attrs_define
class PutMonitoringSitesIdResponse200:
    """
    Attributes:
        id (str):
        site_group_id (str):
        user_id (str):
        owner_kind (str):
        owner_id (str):
        name (str):
        slug (str):
        description (None | str):
        display_order (int):
        created_at (str):
        updated_at (str):
    """

    id: str
    site_group_id: str
    user_id: str
    owner_kind: str
    owner_id: str
    name: str
    slug: str
    description: None | str
    display_order: int
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        site_group_id = self.site_group_id

        user_id = self.user_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        name = self.name

        slug = self.slug

        description: None | str
        description = self.description

        display_order = self.display_order

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "siteGroupId": site_group_id,
                "userId": user_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "name": name,
                "slug": slug,
                "description": description,
                "displayOrder": display_order,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        site_group_id = d.pop("siteGroupId")

        user_id = d.pop("userId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        name = d.pop("name")

        slug = d.pop("slug")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        display_order = d.pop("displayOrder")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        put_monitoring_sites_id_response_200 = cls(
            id=id,
            site_group_id=site_group_id,
            user_id=user_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            slug=slug,
            description=description,
            display_order=display_order,
            created_at=created_at,
            updated_at=updated_at,
        )

        return put_monitoring_sites_id_response_200
