from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentCategoryItemsBody")


@_attrs_define
class PostContentCategoryItemsBody:
    """
    Attributes:
        category_id (str):
        target_kind (str):
        target_id (str):
        ecosystem_id (str | Unset):
        sort_order (int | Unset):
    """

    category_id: str
    target_kind: str
    target_id: str
    ecosystem_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        category_id = self.category_id

        target_kind = self.target_kind

        target_id = self.target_id

        ecosystem_id = self.ecosystem_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "categoryId": category_id,
                "targetKind": target_kind,
                "targetId": target_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category_id = d.pop("categoryId")

        target_kind = d.pop("targetKind")

        target_id = d.pop("targetId")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        post_content_category_items_body = cls(
            category_id=category_id,
            target_kind=target_kind,
            target_id=target_id,
            ecosystem_id=ecosystem_id,
            sort_order=sort_order,
        )

        return post_content_category_items_body
