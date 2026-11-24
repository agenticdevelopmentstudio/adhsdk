from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsItemsByIdResponse200")


@_attrs_define
class PostV1IntegrationsItemsByIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['integrations.item'] | Unset):
    """

    id: str
    owner_kind: str
    owner_id: str
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
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["integrations.item"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

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

        created = self.created

        updated = self.updated

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
                "connection_id": connection_id,
                "external_id": external_id,
                "item_type": item_type,
                "title": title,
                "body": body,
                "state": state,
                "repo_full_name": repo_full_name,
                "repo_url": repo_url,
                "item_url": item_url,
                "number": number,
                "labels": labels,
                "assignees": assignees,
                "is_read": is_read,
                "notification_reason": notification_reason,
                "is_deleted": is_deleted,
                "external_created_at": external_created_at,
                "external_updated_at": external_updated_at,
                "created": created,
                "updated": updated,
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

        connection_id = d.pop("connection_id")

        external_id = d.pop("external_id")

        item_type = d.pop("item_type")

        title = d.pop("title")

        def _parse_body(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        body = _parse_body(d.pop("body"))

        state = d.pop("state")

        repo_full_name = d.pop("repo_full_name")

        def _parse_repo_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        repo_url = _parse_repo_url(d.pop("repo_url"))

        def _parse_item_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        item_url = _parse_item_url(d.pop("item_url"))

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

        is_read = d.pop("is_read")

        def _parse_notification_reason(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        notification_reason = _parse_notification_reason(d.pop("notification_reason"))

        is_deleted = d.pop("is_deleted")

        def _parse_external_created_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_created_at = _parse_external_created_at(d.pop("external_created_at"))

        def _parse_external_updated_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_updated_at = _parse_external_updated_at(d.pop("external_updated_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["integrations.item"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'integrations.item', got '{object_}'")

        post_v1_integrations_items_by_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
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
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_integrations_items_by_id_response_200
