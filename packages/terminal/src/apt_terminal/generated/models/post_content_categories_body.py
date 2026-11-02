from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentCategoriesBody")


@_attrs_define
class PostContentCategoriesBody:
    """
    Attributes:
        name (str):
        ecosystem_id (str | Unset):
        description (str | Unset):
        color (str | Unset):
        icon (str | Unset):
        sort_order (int | Unset):
        sync_txid (int | Unset):
    """

    name: str
    ecosystem_id: str | Unset = UNSET
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    icon: str | Unset = UNSET
    sort_order: int | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        ecosystem_id = self.ecosystem_id

        description = self.description

        color = self.color

        icon = self.icon

        sort_order = self.sort_order

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
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
        name = d.pop("name")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        icon = d.pop("icon", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_content_categories_body = cls(
            name=name,
            ecosystem_id=ecosystem_id,
            description=description,
            color=color,
            icon=icon,
            sort_order=sort_order,
            sync_txid=sync_txid,
        )

        return post_content_categories_body
