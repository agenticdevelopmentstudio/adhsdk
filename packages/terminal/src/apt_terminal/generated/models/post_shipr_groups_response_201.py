from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostShiprGroupsResponse201")


@_attrs_define
class PostShiprGroupsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        user_id (str):
        owner_kind (str):
        owner_id (str):
        parent_id (None | str):
        name (str):
        path (str):
        depth (int):
        position (int):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
    """

    id: str
    ecosystem_id: str
    user_id: str
    owner_kind: str
    owner_id: str
    parent_id: None | str
    name: str
    path: str
    depth: int
    position: int
    created_at: str
    updated_at: str
    deleted_at: None | str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        user_id = self.user_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        parent_id: None | str
        parent_id = self.parent_id

        name = self.name

        path = self.path

        depth = self.depth

        position = self.position

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str
        deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "userId": user_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "parentId": parent_id,
                "name": name,
                "path": path,
                "depth": depth,
                "position": position,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        user_id = d.pop("userId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parentId"))

        name = d.pop("name")

        path = d.pop("path")

        depth = d.pop("depth")

        position = d.pop("position")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        post_shipr_groups_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            user_id=user_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            parent_id=parent_id,
            name=name,
            path=path,
            depth=depth,
            position=position,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
        )

        return post_shipr_groups_response_201
