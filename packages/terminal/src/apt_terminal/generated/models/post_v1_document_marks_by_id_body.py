from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentMarksByIdBody")


@_attrs_define
class PostV1DocumentMarksByIdBody:
    """
    Attributes:
        block_id (str | Unset):
        ecosystem_id (str | Unset):
        mark_type (str | Unset):
        start_anchor (str | Unset):
        end_anchor (str | Unset):
        mark_data (str | Unset):
    """

    block_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    mark_type: str | Unset = UNSET
    start_anchor: str | Unset = UNSET
    end_anchor: str | Unset = UNSET
    mark_data: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        block_id = self.block_id

        ecosystem_id = self.ecosystem_id

        mark_type = self.mark_type

        start_anchor = self.start_anchor

        end_anchor = self.end_anchor

        mark_data = self.mark_data

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if block_id is not UNSET:
            field_dict["block_id"] = block_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if mark_type is not UNSET:
            field_dict["mark_type"] = mark_type
        if start_anchor is not UNSET:
            field_dict["start_anchor"] = start_anchor
        if end_anchor is not UNSET:
            field_dict["end_anchor"] = end_anchor
        if mark_data is not UNSET:
            field_dict["mark_data"] = mark_data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        block_id = d.pop("block_id", UNSET)

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        mark_type = d.pop("mark_type", UNSET)

        start_anchor = d.pop("start_anchor", UNSET)

        end_anchor = d.pop("end_anchor", UNSET)

        mark_data = d.pop("mark_data", UNSET)

        post_v1_document_marks_by_id_body = cls(
            block_id=block_id,
            ecosystem_id=ecosystem_id,
            mark_type=mark_type,
            start_anchor=start_anchor,
            end_anchor=end_anchor,
            mark_data=mark_data,
        )

        return post_v1_document_marks_by_id_body
