from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostDocumentMarksBody")


@_attrs_define
class PostDocumentMarksBody:
    """
    Attributes:
        block_id (str):
        mark_type (str):
        start_anchor (str):
        end_anchor (str):
        ecosystem_id (str | Unset):
        mark_data (str | Unset):
        sync_txid (int | Unset):
    """

    block_id: str
    mark_type: str
    start_anchor: str
    end_anchor: str
    ecosystem_id: str | Unset = UNSET
    mark_data: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        block_id = self.block_id

        mark_type = self.mark_type

        start_anchor = self.start_anchor

        end_anchor = self.end_anchor

        ecosystem_id = self.ecosystem_id

        mark_data = self.mark_data

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "blockId": block_id,
                "markType": mark_type,
                "startAnchor": start_anchor,
                "endAnchor": end_anchor,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if mark_data is not UNSET:
            field_dict["markData"] = mark_data
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        block_id = d.pop("blockId")

        mark_type = d.pop("markType")

        start_anchor = d.pop("startAnchor")

        end_anchor = d.pop("endAnchor")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        mark_data = d.pop("markData", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_document_marks_body = cls(
            block_id=block_id,
            mark_type=mark_type,
            start_anchor=start_anchor,
            end_anchor=end_anchor,
            ecosystem_id=ecosystem_id,
            mark_data=mark_data,
            sync_txid=sync_txid,
        )

        return post_document_marks_body
