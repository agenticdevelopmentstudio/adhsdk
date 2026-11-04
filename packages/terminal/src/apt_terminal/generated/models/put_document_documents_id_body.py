from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutDocumentDocumentsIdBody")


@_attrs_define
class PutDocumentDocumentsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        title (str | Unset):
        doc_type (str | Unset):
        last_op_id (None | str | Unset):
        last_snapshot_id (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    title: str | Unset = UNSET
    doc_type: str | Unset = UNSET
    last_op_id: None | str | Unset = UNSET
    last_snapshot_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        title = self.title

        doc_type = self.doc_type

        last_op_id: None | str | Unset
        if isinstance(self.last_op_id, Unset):
            last_op_id = UNSET
        else:
            last_op_id = self.last_op_id

        last_snapshot_id: None | str | Unset
        if isinstance(self.last_snapshot_id, Unset):
            last_snapshot_id = UNSET
        else:
            last_snapshot_id = self.last_snapshot_id

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if title is not UNSET:
            field_dict["title"] = title
        if doc_type is not UNSET:
            field_dict["docType"] = doc_type
        if last_op_id is not UNSET:
            field_dict["lastOpId"] = last_op_id
        if last_snapshot_id is not UNSET:
            field_dict["lastSnapshotId"] = last_snapshot_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        title = d.pop("title", UNSET)

        doc_type = d.pop("docType", UNSET)

        def _parse_last_op_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_op_id = _parse_last_op_id(d.pop("lastOpId", UNSET))

        def _parse_last_snapshot_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_snapshot_id = _parse_last_snapshot_id(d.pop("lastSnapshotId", UNSET))

        put_document_documents_id_body = cls(
            ecosystem_id=ecosystem_id,
            title=title,
            doc_type=doc_type,
            last_op_id=last_op_id,
            last_snapshot_id=last_snapshot_id,
        )

        return put_document_documents_id_body
