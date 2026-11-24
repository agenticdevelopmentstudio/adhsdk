from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ShiprGroup")


@_attrs_define
class ShiprGroup:
    """A folder in the deployment tree. `path` and `depth` are trigger-maintained.

    Attributes:
        id (str | Unset):
        parent_id (None | str | Unset):
        name (str | Unset):
        path (str | Unset):
        depth (int | Unset):
        position (int | Unset):
    """

    id: str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    name: str | Unset = UNSET
    path: str | Unset = UNSET
    depth: int | Unset = UNSET
    position: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        name = self.name

        path = self.path

        depth = self.depth

        position = self.position

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
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

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

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

        shipr_group = cls(
            id=id,
            parent_id=parent_id,
            name=name,
            path=path,
            depth=depth,
            position=position,
        )

        shipr_group.additional_properties = d
        return shipr_group

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
