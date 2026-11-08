from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostProjectTasksResponse201")


@_attrs_define
class PostProjectTasksResponse201:
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
        description (None | str):
        is_completed (bool):
        priority (int):
        due_date (None | str):
        due_datetime (None | str):
        external_project_id (None | str):
        external_project_name (None | str):
        labels (None | str):
        url (None | str):
        is_deleted (bool):
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
    description: None | str
    is_completed: bool
    priority: int
    due_date: None | str
    due_datetime: None | str
    external_project_id: None | str
    external_project_name: None | str
    labels: None | str
    url: None | str
    is_deleted: bool
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

        description: None | str
        description = self.description

        is_completed = self.is_completed

        priority = self.priority

        due_date: None | str
        due_date = self.due_date

        due_datetime: None | str
        due_datetime = self.due_datetime

        external_project_id: None | str
        external_project_id = self.external_project_id

        external_project_name: None | str
        external_project_name = self.external_project_name

        labels: None | str
        labels = self.labels

        url: None | str
        url = self.url

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
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "connectionId": connection_id,
                "externalId": external_id,
                "sourceProvider": source_provider,
                "title": title,
                "description": description,
                "isCompleted": is_completed,
                "priority": priority,
                "dueDate": due_date,
                "dueDatetime": due_datetime,
                "externalProjectId": external_project_id,
                "externalProjectName": external_project_name,
                "labels": labels,
                "url": url,
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

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        is_completed = d.pop("isCompleted")

        priority = d.pop("priority")

        def _parse_due_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        due_date = _parse_due_date(d.pop("dueDate"))

        def _parse_due_datetime(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        due_datetime = _parse_due_datetime(d.pop("dueDatetime"))

        def _parse_external_project_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_project_id = _parse_external_project_id(d.pop("externalProjectId"))

        def _parse_external_project_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_project_name = _parse_external_project_name(d.pop("externalProjectName"))

        def _parse_labels(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        labels = _parse_labels(d.pop("labels"))

        def _parse_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        url = _parse_url(d.pop("url"))

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

        post_project_tasks_response_201 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            title=title,
            description=description,
            is_completed=is_completed,
            priority=priority,
            due_date=due_date,
            due_datetime=due_datetime,
            external_project_id=external_project_id,
            external_project_name=external_project_name,
            labels=labels,
            url=url,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_project_tasks_response_201
