from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutDocumentOperationsIdBody")


@_attrs_define
class PutDocumentOperationsIdBody:
    """
    Attributes:
        document_id (str | Unset):
        block_id (None | str | Unset):
        ecosystem_id (str | Unset):
        client_id (str | Unset):
        client_seq (int | Unset):
        op_type (str | Unset):
        op_payload (str | Unset):
        undo_group_id (None | str | Unset):
        inverse_of_op_id (None | str | Unset):
        sync_txid (int | Unset):
    """

    document_id: str | Unset = UNSET
    block_id: None | str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    client_id: str | Unset = UNSET
    client_seq: int | Unset = UNSET
    op_type: str | Unset = UNSET
    op_payload: str | Unset = UNSET
    undo_group_id: None | str | Unset = UNSET
    inverse_of_op_id: None | str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        document_id = self.document_id

        block_id: None | str | Unset
        if isinstance(self.block_id, Unset):
            block_id = UNSET
        else:
            block_id = self.block_id

        ecosystem_id = self.ecosystem_id

        client_id = self.client_id

        client_seq = self.client_seq

        op_type = self.op_type

        op_payload = self.op_payload

        undo_group_id: None | str | Unset
        if isinstance(self.undo_group_id, Unset):
            undo_group_id = UNSET
        else:
            undo_group_id = self.undo_group_id

        inverse_of_op_id: None | str | Unset
        if isinstance(self.inverse_of_op_id, Unset):
            inverse_of_op_id = UNSET
        else:
            inverse_of_op_id = self.inverse_of_op_id

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if document_id is not UNSET:
            field_dict["documentId"] = document_id
        if block_id is not UNSET:
            field_dict["blockId"] = block_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if client_id is not UNSET:
            field_dict["clientId"] = client_id
        if client_seq is not UNSET:
            field_dict["clientSeq"] = client_seq
        if op_type is not UNSET:
            field_dict["opType"] = op_type
        if op_payload is not UNSET:
            field_dict["opPayload"] = op_payload
        if undo_group_id is not UNSET:
            field_dict["undoGroupId"] = undo_group_id
        if inverse_of_op_id is not UNSET:
            field_dict["inverseOfOpId"] = inverse_of_op_id
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        document_id = d.pop("documentId", UNSET)

        def _parse_block_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        block_id = _parse_block_id(d.pop("blockId", UNSET))

        ecosystem_id = d.pop("ecosystemId", UNSET)

        client_id = d.pop("clientId", UNSET)

        client_seq = d.pop("clientSeq", UNSET)

        op_type = d.pop("opType", UNSET)

        op_payload = d.pop("opPayload", UNSET)

        def _parse_undo_group_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        undo_group_id = _parse_undo_group_id(d.pop("undoGroupId", UNSET))

        def _parse_inverse_of_op_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        inverse_of_op_id = _parse_inverse_of_op_id(d.pop("inverseOfOpId", UNSET))

        sync_txid = d.pop("syncTxid", UNSET)

        put_document_operations_id_body = cls(
            document_id=document_id,
            block_id=block_id,
            ecosystem_id=ecosystem_id,
            client_id=client_id,
            client_seq=client_seq,
            op_type=op_type,
            op_payload=op_payload,
            undo_group_id=undo_group_id,
            inverse_of_op_id=inverse_of_op_id,
            sync_txid=sync_txid,
        )

        return put_document_operations_id_body
