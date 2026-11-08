from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetIntegrationIntegrationBookmarksIdResponse200")


@_attrs_define
class GetIntegrationIntegrationBookmarksIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        source_provider (str):
        title (str):
        url (str):
        excerpt (None | str):
        note (None | str):
        tags (None | str):
        image_url (None | str):
        collection_id (None | str):
        collection_name (None | str):
        is_favorite (bool):
        is_deleted (bool):
        external_created_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    connection_id: str
    external_id: str
    source_provider: str
    title: str
    url: str
    excerpt: None | str
    note: None | str
    tags: None | str
    image_url: None | str
    collection_id: None | str
    collection_name: None | str
    is_favorite: bool
    is_deleted: bool
    external_created_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        source_provider = self.source_provider

        title = self.title

        url = self.url

        excerpt: None | str
        excerpt = self.excerpt

        note: None | str
        note = self.note

        tags: None | str
        tags = self.tags

        image_url: None | str
        image_url = self.image_url

        collection_id: None | str
        collection_id = self.collection_id

        collection_name: None | str
        collection_name = self.collection_name

        is_favorite = self.is_favorite

        is_deleted = self.is_deleted

        external_created_at: None | str
        external_created_at = self.external_created_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "connectionId": connection_id,
                "externalId": external_id,
                "sourceProvider": source_provider,
                "title": title,
                "url": url,
                "excerpt": excerpt,
                "note": note,
                "tags": tags,
                "imageUrl": image_url,
                "collectionId": collection_id,
                "collectionName": collection_name,
                "isFavorite": is_favorite,
                "isDeleted": is_deleted,
                "externalCreatedAt": external_created_at,
                "createdAt": created_at,
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

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        connection_id = d.pop("connectionId")

        external_id = d.pop("externalId")

        source_provider = d.pop("sourceProvider")

        title = d.pop("title")

        url = d.pop("url")

        def _parse_excerpt(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        excerpt = _parse_excerpt(d.pop("excerpt"))

        def _parse_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        note = _parse_note(d.pop("note"))

        def _parse_tags(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        tags = _parse_tags(d.pop("tags"))

        def _parse_image_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        image_url = _parse_image_url(d.pop("imageUrl"))

        def _parse_collection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        collection_id = _parse_collection_id(d.pop("collectionId"))

        def _parse_collection_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        collection_name = _parse_collection_name(d.pop("collectionName"))

        is_favorite = d.pop("isFavorite")

        is_deleted = d.pop("isDeleted")

        def _parse_external_created_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_created_at = _parse_external_created_at(d.pop("externalCreatedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_integration_integration_bookmarks_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            title=title,
            url=url,
            excerpt=excerpt,
            note=note,
            tags=tags,
            image_url=image_url,
            collection_id=collection_id,
            collection_name=collection_name,
            is_favorite=is_favorite,
            is_deleted=is_deleted,
            external_created_at=external_created_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_integration_integration_bookmarks_id_response_200
