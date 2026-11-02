from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetIntegrationIntegrationPagesResponse200Item")


@_attrs_define
class GetIntegrationIntegrationPagesResponse200Item:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        title (str):
        object_type (str):
        url (None | str):
        icon (None | str):
        parent_type (None | str):
        parent_id (None | str):
        is_archived (bool):
        last_edited_at (None | str):
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
    title: str
    object_type: str
    url: None | str
    icon: None | str
    parent_type: None | str
    parent_id: None | str
    is_archived: bool
    last_edited_at: None | str
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

        title = self.title

        object_type = self.object_type

        url: None | str
        url = self.url

        icon: None | str
        icon = self.icon

        parent_type: None | str
        parent_type = self.parent_type

        parent_id: None | str
        parent_id = self.parent_id

        is_archived = self.is_archived

        last_edited_at: None | str
        last_edited_at = self.last_edited_at

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
                "title": title,
                "objectType": object_type,
                "url": url,
                "icon": icon,
                "parentType": parent_type,
                "parentId": parent_id,
                "isArchived": is_archived,
                "lastEditedAt": last_edited_at,
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

        title = d.pop("title")

        object_type = d.pop("objectType")

        def _parse_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        url = _parse_url(d.pop("url"))

        def _parse_icon(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        icon = _parse_icon(d.pop("icon"))

        def _parse_parent_type(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_type = _parse_parent_type(d.pop("parentType"))

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parentId"))

        is_archived = d.pop("isArchived")

        def _parse_last_edited_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_edited_at = _parse_last_edited_at(d.pop("lastEditedAt"))

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

        get_integration_integration_pages_response_200_item = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            title=title,
            object_type=object_type,
            url=url,
            icon=icon,
            parent_type=parent_type,
            parent_id=parent_id,
            is_archived=is_archived,
            last_edited_at=last_edited_at,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_integration_integration_pages_response_200_item
