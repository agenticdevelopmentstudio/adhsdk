from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ShiprGroupsByIdBody")


@_attrs_define
class PostV1ShiprGroupsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        parent_id (None | str | Unset):
        name (str | Unset):
        path (str | Unset):
        depth (int | Unset):
        position (int | Unset):
        deleted_at (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    name: str | Unset = UNSET
    path: str | Unset = UNSET
    depth: int | Unset = UNSET
    position: int | Unset = UNSET
    deleted_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        name = self.name

        path = self.path

        depth = self.depth

        position = self.position

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if name is not UNSET:
            field_dict["name"] = name
        if path is not UNSET:
            field_dict["path"] = path
        if depth is not UNSET:
            field_dict["depth"] = depth
        if position is not UNSET:
            field_dict["position"] = position
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

        name = d.pop("name", UNSET)

        path = d.pop("path", UNSET)

        depth = d.pop("depth", UNSET)

        position = d.pop("position", UNSET)

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        post_v1_shipr_groups_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            name=name,
            path=path,
            depth=depth,
            position=position,
            deleted_at=deleted_at,
        )

        return post_v1_shipr_groups_by_id_body
