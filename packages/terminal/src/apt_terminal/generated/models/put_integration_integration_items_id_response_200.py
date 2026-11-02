from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutIntegrationIntegrationItemsIdResponse200")


@_attrs_define
class PutIntegrationIntegrationItemsIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        connection_id (str):
        external_id (str):
        item_type (str):
        title (str):
        body (None | str):
        state (str):
        repo_full_name (str):
        repo_url (None | str):
        item_url (None | str):
        number (int | None):
        labels (None | str):
        assignees (None | str):
        is_read (bool):
        notification_reason (None | str):
        is_deleted (bool):
        external_created_at (None | str):
        external_updated_at (None | str):
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
    item_type: str
    title: str
    body: None | str
    state: str
    repo_full_name: str
    repo_url: None | str
    item_url: None | str
    number: int | None
    labels: None | str
    assignees: None | str
    is_read: bool
    notification_reason: None | str
    is_deleted: bool
    external_created_at: None | str
    external_updated_at: None | str
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

        item_type = self.item_type

        title = self.title

        body: None | str
        body = self.body

        state = self.state

        repo_full_name = self.repo_full_name

        repo_url: None | str
        repo_url = self.repo_url

        item_url: None | str
        item_url = self.item_url

        number: int | None
        number = self.number

        labels: None | str
        labels = self.labels

        assignees: None | str
        assignees = self.assignees

        is_read = self.is_read

        notification_reason: None | str
        notification_reason = self.notification_reason

        is_deleted = self.is_deleted

        external_created_at: None | str
        external_created_at = self.external_created_at

        external_updated_at: None | str
        external_updated_at = self.external_updated_at

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
                "itemType": item_type,
                "title": title,
                "body": body,
                "state": state,
                "repoFullName": repo_full_name,
                "repoUrl": repo_url,
                "itemUrl": item_url,
                "number": number,
                "labels": labels,
                "assignees": assignees,
                "isRead": is_read,
                "notificationReason": notification_reason,
                "isDeleted": is_deleted,
                "externalCreatedAt": external_created_at,
                "externalUpdatedAt": external_updated_at,
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

        item_type = d.pop("itemType")

        title = d.pop("title")

        def _parse_body(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        body = _parse_body(d.pop("body"))

        state = d.pop("state")

        repo_full_name = d.pop("repoFullName")

        def _parse_repo_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        repo_url = _parse_repo_url(d.pop("repoUrl"))

        def _parse_item_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        item_url = _parse_item_url(d.pop("itemUrl"))

        def _parse_number(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        number = _parse_number(d.pop("number"))

        def _parse_labels(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        labels = _parse_labels(d.pop("labels"))

        def _parse_assignees(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        assignees = _parse_assignees(d.pop("assignees"))

        is_read = d.pop("isRead")

        def _parse_notification_reason(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        notification_reason = _parse_notification_reason(d.pop("notificationReason"))

        is_deleted = d.pop("isDeleted")

        def _parse_external_created_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_created_at = _parse_external_created_at(d.pop("externalCreatedAt"))

        def _parse_external_updated_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_updated_at = _parse_external_updated_at(d.pop("externalUpdatedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        put_integration_integration_items_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            item_type=item_type,
            title=title,
            body=body,
            state=state,
            repo_full_name=repo_full_name,
            repo_url=repo_url,
            item_url=item_url,
            number=number,
            labels=labels,
            assignees=assignees,
            is_read=is_read,
            notification_reason=notification_reason,
            is_deleted=is_deleted,
            external_created_at=external_created_at,
            external_updated_at=external_updated_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return put_integration_integration_items_id_response_200
