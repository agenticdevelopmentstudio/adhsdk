from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetDocumentDocumentsResponse200Item")


@_attrs_define
class GetDocumentDocumentsResponse200Item:
    """
    Attributes:
        id (str):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        title (str):
        doc_type (str):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        last_op_id (None | str):
        last_snapshot_id (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    title: str
    doc_type: str
    created_at: str
    updated_at: str
    is_deleted: bool
    last_op_id: None | str
    last_snapshot_id: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        title = self.title

        doc_type = self.doc_type

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        last_op_id: None | str
        last_op_id = self.last_op_id

        last_snapshot_id: None | str
        last_snapshot_id = self.last_snapshot_id

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "title": title,
                "docType": doc_type,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
                "lastOpId": last_op_id,
                "lastSnapshotId": last_snapshot_id,
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

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        title = d.pop("title")

        doc_type = d.pop("docType")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        def _parse_last_op_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_op_id = _parse_last_op_id(d.pop("lastOpId"))

        def _parse_last_snapshot_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_snapshot_id = _parse_last_snapshot_id(d.pop("lastSnapshotId"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_document_documents_response_200_item = cls(
            id=id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            title=title,
            doc_type=doc_type,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            last_op_id=last_op_id,
            last_snapshot_id=last_snapshot_id,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_document_documents_response_200_item
