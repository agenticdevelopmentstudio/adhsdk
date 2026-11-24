from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprGroupsByIdResponse200")


@_attrs_define
class PostV1ShiprGroupsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        user_id (str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        parent_id (None | str):
        name (str):
        path (str):
        depth (int):
        position (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        object_ (Literal['shipr.group'] | Unset):
    """

    id: str
    ecosystem_id: str
    user_id: str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    parent_id: None | str
    name: str
    path: str
    depth: int
    position: int
    created: int
    updated: int
    deleted_at: None | str
    object_: Literal["shipr.group"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        parent_id: None | str
        parent_id = self.parent_id

        name = self.name

        path = self.path

        depth = self.depth

        position = self.position

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "parent_id": parent_id,
                "name": name,
                "path": path,
                "depth": depth,
                "position": position,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        user_id = d.pop("user_id")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parent_id"))

        name = d.pop("name")

        path = d.pop("path")

        depth = d.pop("depth")

        position = d.pop("position")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        object_ = cast(Literal["shipr.group"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.group" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.group', got '{object_}'")

        post_v1_shipr_groups_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            parent_id=parent_id,
            name=name,
            path=path,
            depth=depth,
            position=position,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            object_=object_,
        )

        return post_v1_shipr_groups_by_id_response_200
