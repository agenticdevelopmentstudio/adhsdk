from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetMonitoringSiteGroupsResponse200Item")


@_attrs_define
class GetMonitoringSiteGroupsResponse200Item:
    """
    Attributes:
        id (str):
        user_id (str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        name (str):
        slug (str):
        description (None | str):
        retention_days (int):
        display_order (int):
        created_at (str):
        updated_at (str):
    """

    id: str
    user_id: str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    name: str
    slug: str
    description: None | str
    retention_days: int
    display_order: int
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        name = self.name

        slug = self.slug

        description: None | str
        description = self.description

        retention_days = self.retention_days

        display_order = self.display_order

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "userId": user_id,
                "authorKind": author_kind,
                "authorId": author_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "name": name,
                "slug": slug,
                "description": description,
                "retentionDays": retention_days,
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

        user_id = d.pop("userId")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        name = d.pop("name")

        slug = d.pop("slug")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        retention_days = d.pop("retentionDays")

        display_order = d.pop("displayOrder")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        get_monitoring_site_groups_response_200_item = cls(
            id=id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            slug=slug,
            description=description,
            retention_days=retention_days,
            display_order=display_order,
            created_at=created_at,
            updated_at=updated_at,
        )

        return get_monitoring_site_groups_response_200_item
