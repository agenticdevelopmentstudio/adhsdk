from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetIntegrationIntegrationSocialNotificationsResponse200Item")


@_attrs_define
class GetIntegrationIntegrationSocialNotificationsResponse200Item:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        source_provider (str):
        notification_type (str):
        title (None | str):
        body (None | str):
        author_handle (None | str):
        author_display_name (None | str):
        item_url (None | str):
        is_read (bool):
        is_deleted (bool):
        external_created_at (None | str):
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
    notification_type: str
    title: None | str
    body: None | str
    author_handle: None | str
    author_display_name: None | str
    item_url: None | str
    is_read: bool
    is_deleted: bool
    external_created_at: None | str
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

        notification_type = self.notification_type

        title: None | str
        title = self.title

        body: None | str
        body = self.body

        author_handle: None | str
        author_handle = self.author_handle

        author_display_name: None | str
        author_display_name = self.author_display_name

        item_url: None | str
        item_url = self.item_url

        is_read = self.is_read

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
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "connectionId": connection_id,
                "externalId": external_id,
                "sourceProvider": source_provider,
                "notificationType": notification_type,
                "title": title,
                "body": body,
                "authorHandle": author_handle,
                "authorDisplayName": author_display_name,
                "itemUrl": item_url,
                "isRead": is_read,
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

        notification_type = d.pop("notificationType")

        def _parse_title(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        title = _parse_title(d.pop("title"))

        def _parse_body(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        body = _parse_body(d.pop("body"))

        def _parse_author_handle(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_handle = _parse_author_handle(d.pop("authorHandle"))

        def _parse_author_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_display_name = _parse_author_display_name(d.pop("authorDisplayName"))

        def _parse_item_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        item_url = _parse_item_url(d.pop("itemUrl"))

        is_read = d.pop("isRead")

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

        get_integration_integration_social_notifications_response_200_item = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            notification_type=notification_type,
            title=title,
            body=body,
            author_handle=author_handle,
            author_display_name=author_display_name,
            item_url=item_url,
            is_read=is_read,
            is_deleted=is_deleted,
            external_created_at=external_created_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_integration_integration_social_notifications_response_200_item
