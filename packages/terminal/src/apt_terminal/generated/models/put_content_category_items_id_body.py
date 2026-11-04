from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentCategoryItemsIdBody")


@_attrs_define
class PutContentCategoryItemsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        category_id (str | Unset):
        target_kind (str | Unset):
        target_id (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    category_id: str | Unset = UNSET
    target_kind: str | Unset = UNSET
    target_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        category_id = self.category_id

        target_kind = self.target_kind

        target_id = self.target_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if category_id is not UNSET:
            field_dict["categoryId"] = category_id
        if target_kind is not UNSET:
            field_dict["targetKind"] = target_kind
        if target_id is not UNSET:
            field_dict["targetId"] = target_id
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        category_id = d.pop("categoryId", UNSET)

        target_kind = d.pop("targetKind", UNSET)

        target_id = d.pop("targetId", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        put_content_category_items_id_body = cls(
            ecosystem_id=ecosystem_id,
            category_id=category_id,
            target_kind=target_kind,
            target_id=target_id,
            sort_order=sort_order,
        )

        return put_content_category_items_id_body
