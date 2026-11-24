from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentKeywordItemsByIdBody")


@_attrs_define
class PostV1ContentKeywordItemsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        keyword_id (str | Unset):
        target_kind (str | Unset):
        target_id (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    keyword_id: str | Unset = UNSET
    target_kind: str | Unset = UNSET
    target_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        keyword_id = self.keyword_id

        target_kind = self.target_kind

        target_id = self.target_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if keyword_id is not UNSET:
            field_dict["keyword_id"] = keyword_id
        if target_kind is not UNSET:
            field_dict["target_kind"] = target_kind
        if target_id is not UNSET:
            field_dict["target_id"] = target_id
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        keyword_id = d.pop("keyword_id", UNSET)

        target_kind = d.pop("target_kind", UNSET)

        target_id = d.pop("target_id", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_keyword_items_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            keyword_id=keyword_id,
            target_kind=target_kind,
            target_id=target_id,
            sort_order=sort_order,
        )

        return post_v1_content_keyword_items_by_id_body
