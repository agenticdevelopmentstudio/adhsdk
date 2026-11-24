from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentKeywordItemsBody")


@_attrs_define
class PostV1ContentKeywordItemsBody:
    """
    Attributes:
        keyword_id (str):
        target_kind (str):
        target_id (str):
        ecosystem_id (str | Unset):
        sort_order (int | Unset):
    """

    keyword_id: str
    target_kind: str
    target_id: str
    ecosystem_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        keyword_id = self.keyword_id

        target_kind = self.target_kind

        target_id = self.target_id

        ecosystem_id = self.ecosystem_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "keyword_id": keyword_id,
                "target_kind": target_kind,
                "target_id": target_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        keyword_id = d.pop("keyword_id")

        target_kind = d.pop("target_kind")

        target_id = d.pop("target_id")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_keyword_items_body = cls(
            keyword_id=keyword_id,
            target_kind=target_kind,
            target_id=target_id,
            ecosystem_id=ecosystem_id,
            sort_order=sort_order,
        )

        return post_v1_content_keyword_items_body
