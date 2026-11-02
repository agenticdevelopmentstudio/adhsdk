from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentCategoriesIdBody")


@_attrs_define
class PutContentCategoriesIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        description (str | Unset):
        color (str | Unset):
        icon (str | Unset):
        sort_order (int | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    icon: str | Unset = UNSET
    sort_order: int | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        color = self.color

        icon = self.icon

        sort_order = self.sort_order

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if icon is not UNSET:
            field_dict["icon"] = icon
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        icon = d.pop("icon", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_categories_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            color=color,
            icon=icon,
            sort_order=sort_order,
            sync_txid=sync_txid,
        )

        return put_content_categories_id_body
