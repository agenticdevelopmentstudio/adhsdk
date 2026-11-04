from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentCategoryEdgesIdBody")


@_attrs_define
class PutContentCategoryEdgesIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        parent_id (str | Unset):
        child_id (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    parent_id: str | Unset = UNSET
    child_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        parent_id = self.parent_id

        child_id = self.child_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if parent_id is not UNSET:
            field_dict["parentId"] = parent_id
        if child_id is not UNSET:
            field_dict["childId"] = child_id
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        parent_id = d.pop("parentId", UNSET)

        child_id = d.pop("childId", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        put_content_category_edges_id_body = cls(
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            child_id=child_id,
            sort_order=sort_order,
        )

        return put_content_category_edges_id_body
