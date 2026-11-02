from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetDocumentBlocksIdResponse200")


@_attrs_define
class GetDocumentBlocksIdResponse200:
    """
    Attributes:
        id (str):
        document_id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        position (str):
        block_type (str):
        content_text (str):
        content_meta (str):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        last_op_id (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    document_id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    position: str
    block_type: str
    content_text: str
    content_meta: str
    created_at: str
    updated_at: str
    is_deleted: bool
    last_op_id: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        document_id = self.document_id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        position = self.position

        block_type = self.block_type

        content_text = self.content_text

        content_meta = self.content_meta

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        last_op_id: None | str
        last_op_id = self.last_op_id

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "documentId": document_id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "position": position,
                "blockType": block_type,
                "contentText": content_text,
                "contentMeta": content_meta,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
                "lastOpId": last_op_id,
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

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        position = d.pop("position")

        block_type = d.pop("blockType")

        content_text = d.pop("contentText")

        content_meta = d.pop("contentMeta")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        def _parse_last_op_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_op_id = _parse_last_op_id(d.pop("lastOpId"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_document_blocks_id_response_200 = cls(
            id=id,
            document_id=document_id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            position=position,
            block_type=block_type,
            content_text=content_text,
            content_meta=content_meta,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            last_op_id=last_op_id,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_document_blocks_id_response_200
