from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutContentUrlsIdResponse200")


@_attrs_define
class PutContentUrlsIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        original_url (str):
        canonical_url (str):
        canonical_url_hash (str):
        title (None | str):
        description (None | str):
        note (None | str):
        preview_storage_key (None | str):
        preview_url (None | str):
        preview_status (str):
        preview_error (None | str):
        preview_generated_at (None | str):
        preview_attempts (int):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
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
    original_url: str
    canonical_url: str
    canonical_url_hash: str
    title: None | str
    description: None | str
    note: None | str
    preview_storage_key: None | str
    preview_url: None | str
    preview_status: str
    preview_error: None | str
    preview_generated_at: None | str
    preview_attempts: int
    created_at: str
    updated_at: str
    is_deleted: bool
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

        original_url = self.original_url

        canonical_url = self.canonical_url

        canonical_url_hash = self.canonical_url_hash

        title: None | str
        title = self.title

        description: None | str
        description = self.description

        note: None | str
        note = self.note

        preview_storage_key: None | str
        preview_storage_key = self.preview_storage_key

        preview_url: None | str
        preview_url = self.preview_url

        preview_status = self.preview_status

        preview_error: None | str
        preview_error = self.preview_error

        preview_generated_at: None | str
        preview_generated_at = self.preview_generated_at

        preview_attempts = self.preview_attempts

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
                "customerId": customer_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "originalUrl": original_url,
                "canonicalUrl": canonical_url,
                "canonicalUrlHash": canonical_url_hash,
                "title": title,
                "description": description,
                "note": note,
                "previewStorageKey": preview_storage_key,
                "previewUrl": preview_url,
                "previewStatus": preview_status,
                "previewError": preview_error,
                "previewGeneratedAt": preview_generated_at,
                "previewAttempts": preview_attempts,
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

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        original_url = d.pop("originalUrl")

        canonical_url = d.pop("canonicalUrl")

        canonical_url_hash = d.pop("canonicalUrlHash")

        def _parse_title(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        title = _parse_title(d.pop("title"))

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        note = _parse_note(d.pop("note"))

        def _parse_preview_storage_key(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_storage_key = _parse_preview_storage_key(d.pop("previewStorageKey"))

        def _parse_preview_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_url = _parse_preview_url(d.pop("previewUrl"))

        preview_status = d.pop("previewStatus")

        def _parse_preview_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_error = _parse_preview_error(d.pop("previewError"))

        def _parse_preview_generated_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_generated_at = _parse_preview_generated_at(d.pop("previewGeneratedAt"))

        preview_attempts = d.pop("previewAttempts")

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

        put_content_urls_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            original_url=original_url,
            canonical_url=canonical_url,
            canonical_url_hash=canonical_url_hash,
            title=title,
            description=description,
            note=note,
            preview_storage_key=preview_storage_key,
            preview_url=preview_url,
            preview_status=preview_status,
            preview_error=preview_error,
            preview_generated_at=preview_generated_at,
            preview_attempts=preview_attempts,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return put_content_urls_id_response_200
