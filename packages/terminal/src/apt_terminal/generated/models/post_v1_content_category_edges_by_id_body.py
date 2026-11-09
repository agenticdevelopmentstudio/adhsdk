from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentCategoryEdgesByIdBody")


@_attrs_define
class PostV1ContentCategoryEdgesByIdBody:
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
            field_dict["ecosystem_id"] = ecosystem_id
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if child_id is not UNSET:
            field_dict["child_id"] = child_id
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        parent_id = d.pop("parent_id", UNSET)

        child_id = d.pop("child_id", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_category_edges_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            parent_id=parent_id,
            child_id=child_id,
            sort_order=sort_order,
        )

        return post_v1_content_category_edges_by_id_body
