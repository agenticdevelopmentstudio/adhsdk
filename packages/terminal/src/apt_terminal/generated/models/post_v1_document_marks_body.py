from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentMarksBody")


@_attrs_define
class PostV1DocumentMarksBody:
    """
    Attributes:
        block_id (str):
        mark_type (str):
        start_anchor (str):
        end_anchor (str):
        ecosystem_id (str | Unset):
        mark_data (str | Unset):
    """

    block_id: str
    mark_type: str
    start_anchor: str
    end_anchor: str
    ecosystem_id: str | Unset = UNSET
    mark_data: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        block_id = self.block_id

        mark_type = self.mark_type

        start_anchor = self.start_anchor

        end_anchor = self.end_anchor

        ecosystem_id = self.ecosystem_id

        mark_data = self.mark_data

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "block_id": block_id,
                "mark_type": mark_type,
                "start_anchor": start_anchor,
                "end_anchor": end_anchor,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if mark_data is not UNSET:
            field_dict["mark_data"] = mark_data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        block_id = d.pop("block_id")

        mark_type = d.pop("mark_type")

        start_anchor = d.pop("start_anchor")

        end_anchor = d.pop("end_anchor")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        mark_data = d.pop("mark_data", UNSET)

        post_v1_document_marks_body = cls(
            block_id=block_id,
            mark_type=mark_type,
            start_anchor=start_anchor,
            end_anchor=end_anchor,
            ecosystem_id=ecosystem_id,
            mark_data=mark_data,
        )

        return post_v1_document_marks_body
