from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetDocumentOperationsIdResponse200")


@_attrs_define
class GetDocumentOperationsIdResponse200:
    """
    Attributes:
        id (str):
        document_id (str):
        block_id (None | str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        client_id (str):
        client_seq (int):
        op_type (str):
        op_payload (str):
        created_at (str):
        undo_group_id (None | str):
        inverse_of_op_id (None | str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    document_id: str
    block_id: None | str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    client_id: str
    client_seq: int
    op_type: str
    op_payload: str
    created_at: str
    undo_group_id: None | str
    inverse_of_op_id: None | str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        document_id = self.document_id

        block_id: None | str
        block_id = self.block_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        client_id = self.client_id

        client_seq = self.client_seq

        op_type = self.op_type

        op_payload = self.op_payload

        created_at = self.created_at

        undo_group_id: None | str
        undo_group_id = self.undo_group_id

        inverse_of_op_id: None | str
        inverse_of_op_id = self.inverse_of_op_id

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "documentId": document_id,
                "blockId": block_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "clientId": client_id,
                "clientSeq": client_seq,
                "opType": op_type,
                "opPayload": op_payload,
                "createdAt": created_at,
                "undoGroupId": undo_group_id,
                "inverseOfOpId": inverse_of_op_id,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        document_id = d.pop("documentId")

        def _parse_block_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        block_id = _parse_block_id(d.pop("blockId"))

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        client_id = d.pop("clientId")

        client_seq = d.pop("clientSeq")

        op_type = d.pop("opType")

        op_payload = d.pop("opPayload")

        created_at = d.pop("createdAt")

        def _parse_undo_group_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        undo_group_id = _parse_undo_group_id(d.pop("undoGroupId"))

        def _parse_inverse_of_op_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        inverse_of_op_id = _parse_inverse_of_op_id(d.pop("inverseOfOpId"))

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_document_operations_id_response_200 = cls(
            id=id,
            document_id=document_id,
            block_id=block_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            client_id=client_id,
            client_seq=client_seq,
            op_type=op_type,
            op_payload=op_payload,
            created_at=created_at,
            undo_group_id=undo_group_id,
            inverse_of_op_id=inverse_of_op_id,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_document_operations_id_response_200
