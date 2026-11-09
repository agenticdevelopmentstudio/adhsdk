from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentBlocksBody")


@_attrs_define
class PostV1DocumentBlocksBody:
    """
    Attributes:
        document_id (str):
        position (str):
        block_type (str):
        ecosystem_id (str | Unset):
        content_text (str | Unset):
        content_meta (str | Unset):
        last_op_id (None | str | Unset):
    """

    document_id: str
    position: str
    block_type: str
    ecosystem_id: str | Unset = UNSET
    content_text: str | Unset = UNSET
    content_meta: str | Unset = UNSET
    last_op_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        document_id = self.document_id

        position = self.position

        block_type = self.block_type

        ecosystem_id = self.ecosystem_id

        content_text = self.content_text

        content_meta = self.content_meta

        last_op_id: None | str | Unset
        if isinstance(self.last_op_id, Unset):
            last_op_id = UNSET
        else:
            last_op_id = self.last_op_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "document_id": document_id,
                "position": position,
                "block_type": block_type,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if content_text is not UNSET:
            field_dict["content_text"] = content_text
        if content_meta is not UNSET:
            field_dict["content_meta"] = content_meta
        if last_op_id is not UNSET:
            field_dict["last_op_id"] = last_op_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        document_id = d.pop("document_id")

        position = d.pop("position")

        block_type = d.pop("block_type")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        content_text = d.pop("content_text", UNSET)

        content_meta = d.pop("content_meta", UNSET)

        def _parse_last_op_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_op_id = _parse_last_op_id(d.pop("last_op_id", UNSET))

        post_v1_document_blocks_body = cls(
            document_id=document_id,
            position=position,
            block_type=block_type,
            ecosystem_id=ecosystem_id,
            content_text=content_text,
            content_meta=content_meta,
            last_op_id=last_op_id,
        )

        return post_v1_document_blocks_body
