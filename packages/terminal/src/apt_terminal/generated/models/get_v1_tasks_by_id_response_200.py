from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1TasksByIdResponse200")


@_attrs_define
class GetV1TasksByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['task'] | Unset):
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
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["task"] | Unset = UNSET

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
                "source_provider": source_provider,
                "title": title,
                "description": description,
                "is_completed": is_completed,
                "priority": priority,
                "due_date": due_date,
                "due_datetime": due_datetime,
                "external_project_id": external_project_id,
                "external_project_name": external_project_name,
                "labels": labels,
                "url": url,
                "is_deleted": is_deleted,
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

        source_provider = d.pop("source_provider")

        title = d.pop("title")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        is_completed = d.pop("is_completed")

        priority = d.pop("priority")

        def _parse_due_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        due_date = _parse_due_date(d.pop("due_date"))

        def _parse_due_datetime(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        due_datetime = _parse_due_datetime(d.pop("due_datetime"))

        def _parse_external_project_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_project_id = _parse_external_project_id(d.pop("external_project_id"))

        def _parse_external_project_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_project_name = _parse_external_project_name(d.pop("external_project_name"))

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

        is_deleted = d.pop("is_deleted")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["task"] | Unset, d.pop("object", UNSET))
        if object_ != "task" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'task', got '{object_}'")

        get_v1_tasks_by_id_response_200 = cls(
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
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_tasks_by_id_response_200
