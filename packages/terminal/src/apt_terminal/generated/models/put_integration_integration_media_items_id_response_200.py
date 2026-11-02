from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutIntegrationIntegrationMediaItemsIdResponse200")


@_attrs_define
class PutIntegrationIntegrationMediaItemsIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        source_provider (str):
        media_type (str):
        title (str):
        artist (None | str):
        album (None | str):
        image_url (None | str):
        external_url (None | str):
        duration_ms (int | None):
        popularity (int | None):
        is_saved (bool):
        last_played_at (None | str):
        is_deleted (bool):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    connection_id: str
    external_id: str
    source_provider: str
    media_type: str
    title: str
    artist: None | str
    album: None | str
    image_url: None | str
    external_url: None | str
    duration_ms: int | None
    popularity: int | None
    is_saved: bool
    last_played_at: None | str
    is_deleted: bool
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        source_provider = self.source_provider

        media_type = self.media_type

        title = self.title

        artist: None | str
        artist = self.artist

        album: None | str
        album = self.album

        image_url: None | str
        image_url = self.image_url

        external_url: None | str
        external_url = self.external_url

        duration_ms: int | None
        duration_ms = self.duration_ms

        popularity: int | None
        popularity = self.popularity

        is_saved = self.is_saved

        last_played_at: None | str
        last_played_at = self.last_played_at

        is_deleted = self.is_deleted

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
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "connectionId": connection_id,
                "externalId": external_id,
                "sourceProvider": source_provider,
                "mediaType": media_type,
                "title": title,
                "artist": artist,
                "album": album,
                "imageUrl": image_url,
                "externalUrl": external_url,
                "durationMs": duration_ms,
                "popularity": popularity,
                "isSaved": is_saved,
                "lastPlayedAt": last_played_at,
                "isDeleted": is_deleted,
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

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        connection_id = d.pop("connectionId")

        external_id = d.pop("externalId")

        source_provider = d.pop("sourceProvider")

        media_type = d.pop("mediaType")

        title = d.pop("title")

        def _parse_artist(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        artist = _parse_artist(d.pop("artist"))

        def _parse_album(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        album = _parse_album(d.pop("album"))

        def _parse_image_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        image_url = _parse_image_url(d.pop("imageUrl"))

        def _parse_external_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_url = _parse_external_url(d.pop("externalUrl"))

        def _parse_duration_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        duration_ms = _parse_duration_ms(d.pop("durationMs"))

        def _parse_popularity(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        popularity = _parse_popularity(d.pop("popularity"))

        is_saved = d.pop("isSaved")

        def _parse_last_played_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_played_at = _parse_last_played_at(d.pop("lastPlayedAt"))

        is_deleted = d.pop("isDeleted")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        put_integration_integration_media_items_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            media_type=media_type,
            title=title,
            artist=artist,
            album=album,
            image_url=image_url,
            external_url=external_url,
            duration_ms=duration_ms,
            popularity=popularity,
            is_saved=is_saved,
            last_played_at=last_played_at,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return put_integration_integration_media_items_id_response_200
