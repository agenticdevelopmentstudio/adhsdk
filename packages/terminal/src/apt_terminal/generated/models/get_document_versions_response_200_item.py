from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetDocumentVersionsResponse200Item")


@_attrs_define
class GetDocumentVersionsResponse200Item:
    """
    Attributes:
        id (str):
        document_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        name (str):
        description (str):
        pinned_op_id (str):
        pinned_sync_version (int):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    document_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    name: str
    description: str
    pinned_op_id: str
    pinned_sync_version: int
    created_at: str
    updated_at: str
    is_deleted: bool
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        document_id = self.document_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        name = self.name

        description = self.description

        pinned_op_id = self.pinned_op_id

        pinned_sync_version = self.pinned_sync_version

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "documentId": document_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "name": name,
                "description": description,
                "pinnedOpId": pinned_op_id,
                "pinnedSyncVersion": pinned_sync_version,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
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

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        name = d.pop("name")

        description = d.pop("description")

        pinned_op_id = d.pop("pinnedOpId")

        pinned_sync_version = d.pop("pinnedSyncVersion")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_document_versions_response_200_item = cls(
            id=id,
            document_id=document_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            name=name,
            description=description,
            pinned_op_id=pinned_op_id,
            pinned_sync_version=pinned_sync_version,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_document_versions_response_200_item
