from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentUrlsResponse201")


@_attrs_define
class PostV1ContentUrlsResponse201:
    """
    Attributes:
        id (str):
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['content.url'] | Unset):
    """

    id: str
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
    created: int
    updated: int
    is_deleted: bool
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["content.url"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

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

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "original_url": original_url,
                "canonical_url": canonical_url,
                "canonical_url_hash": canonical_url_hash,
                "title": title,
                "description": description,
                "note": note,
                "preview_storage_key": preview_storage_key,
                "preview_url": preview_url,
                "preview_status": preview_status,
                "preview_error": preview_error,
                "preview_generated_at": preview_generated_at,
                "preview_attempts": preview_attempts,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        original_url = d.pop("original_url")

        canonical_url = d.pop("canonical_url")

        canonical_url_hash = d.pop("canonical_url_hash")

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

        preview_storage_key = _parse_preview_storage_key(d.pop("preview_storage_key"))

        def _parse_preview_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_url = _parse_preview_url(d.pop("preview_url"))

        preview_status = d.pop("preview_status")

        def _parse_preview_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_error = _parse_preview_error(d.pop("preview_error"))

        def _parse_preview_generated_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preview_generated_at = _parse_preview_generated_at(d.pop("preview_generated_at"))

        preview_attempts = d.pop("preview_attempts")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["content.url"] | Unset, d.pop("object", UNSET))
        if object_ != "content.url" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.url', got '{object_}'")

        post_v1_content_urls_response_201 = cls(
            id=id,
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
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_content_urls_response_201
