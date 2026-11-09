from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentBlocksByIdBody")


@_attrs_define
class PostV1DocumentBlocksByIdBody:
    """
    Attributes:
        document_id (str | Unset):
        ecosystem_id (str | Unset):
        position (str | Unset):
        block_type (str | Unset):
        content_text (str | Unset):
        content_meta (str | Unset):
        last_op_id (None | str | Unset):
    """

    document_id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    position: str | Unset = UNSET
    block_type: str | Unset = UNSET
    content_text: str | Unset = UNSET
    content_meta: str | Unset = UNSET
    last_op_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        document_id = self.document_id

        ecosystem_id = self.ecosystem_id

        position = self.position

        block_type = self.block_type

        content_text = self.content_text

        content_meta = self.content_meta

        last_op_id: None | str | Unset
        if isinstance(self.last_op_id, Unset):
            last_op_id = UNSET
        else:
            last_op_id = self.last_op_id

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if document_id is not UNSET:
            field_dict["document_id"] = document_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if position is not UNSET:
            field_dict["position"] = position
        if block_type is not UNSET:
            field_dict["block_type"] = block_type
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
        document_id = d.pop("document_id", UNSET)

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        position = d.pop("position", UNSET)

        block_type = d.pop("block_type", UNSET)

        content_text = d.pop("content_text", UNSET)

        content_meta = d.pop("content_meta", UNSET)

        def _parse_last_op_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_op_id = _parse_last_op_id(d.pop("last_op_id", UNSET))

        post_v1_document_blocks_by_id_body = cls(
            document_id=document_id,
            ecosystem_id=ecosystem_id,
            position=position,
            block_type=block_type,
            content_text=content_text,
            content_meta=content_meta,
            last_op_id=last_op_id,
        )

        return post_v1_document_blocks_by_id_body
