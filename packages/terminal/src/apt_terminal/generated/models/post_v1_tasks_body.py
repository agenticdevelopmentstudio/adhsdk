from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1TasksBody")


@_attrs_define
class PostV1TasksBody:
    """
    Attributes:
        connection_id (str):
        external_id (str):
        source_provider (str):
        title (str):
        ecosystem_id (str | Unset):
        description (None | str | Unset):
        is_completed (bool | Unset):
        priority (int | Unset):
        due_date (None | str | Unset):
        due_datetime (None | str | Unset):
        external_project_id (None | str | Unset):
        external_project_name (None | str | Unset):
        labels (None | str | Unset):
        url (None | str | Unset):
    """

    connection_id: str
    external_id: str
    source_provider: str
    title: str
    ecosystem_id: str | Unset = UNSET
    description: None | str | Unset = UNSET
    is_completed: bool | Unset = UNSET
    priority: int | Unset = UNSET
    due_date: None | str | Unset = UNSET
    due_datetime: None | str | Unset = UNSET
    external_project_id: None | str | Unset = UNSET
    external_project_name: None | str | Unset = UNSET
    labels: None | str | Unset = UNSET
    url: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        connection_id = self.connection_id

        external_id = self.external_id

        source_provider = self.source_provider

        title = self.title

        ecosystem_id = self.ecosystem_id

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        is_completed = self.is_completed

        priority = self.priority

        due_date: None | str | Unset
        if isinstance(self.due_date, Unset):
            due_date = UNSET
        else:
            due_date = self.due_date

        due_datetime: None | str | Unset
        if isinstance(self.due_datetime, Unset):
            due_datetime = UNSET
        else:
            due_datetime = self.due_datetime

        external_project_id: None | str | Unset
        if isinstance(self.external_project_id, Unset):
            external_project_id = UNSET
        else:
            external_project_id = self.external_project_id

        external_project_name: None | str | Unset
        if isinstance(self.external_project_name, Unset):
            external_project_name = UNSET
        else:
            external_project_name = self.external_project_name

        labels: None | str | Unset
        if isinstance(self.labels, Unset):
            labels = UNSET
        else:
            labels = self.labels

        url: None | str | Unset
        if isinstance(self.url, Unset):
            url = UNSET
        else:
            url = self.url

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "connection_id": connection_id,
                "external_id": external_id,
                "source_provider": source_provider,
                "title": title,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if description is not UNSET:
            field_dict["description"] = description
        if is_completed is not UNSET:
            field_dict["is_completed"] = is_completed
        if priority is not UNSET:
            field_dict["priority"] = priority
        if due_date is not UNSET:
            field_dict["due_date"] = due_date
        if due_datetime is not UNSET:
            field_dict["due_datetime"] = due_datetime
        if external_project_id is not UNSET:
            field_dict["external_project_id"] = external_project_id
        if external_project_name is not UNSET:
            field_dict["external_project_name"] = external_project_name
        if labels is not UNSET:
            field_dict["labels"] = labels
        if url is not UNSET:
            field_dict["url"] = url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        connection_id = d.pop("connection_id")

        external_id = d.pop("external_id")

        source_provider = d.pop("source_provider")

        title = d.pop("title")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        is_completed = d.pop("is_completed", UNSET)

        priority = d.pop("priority", UNSET)

        def _parse_due_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        due_date = _parse_due_date(d.pop("due_date", UNSET))

        def _parse_due_datetime(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        due_datetime = _parse_due_datetime(d.pop("due_datetime", UNSET))

        def _parse_external_project_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_project_id = _parse_external_project_id(d.pop("external_project_id", UNSET))

        def _parse_external_project_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_project_name = _parse_external_project_name(d.pop("external_project_name", UNSET))

        def _parse_labels(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        labels = _parse_labels(d.pop("labels", UNSET))

        def _parse_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        url = _parse_url(d.pop("url", UNSET))

        post_v1_tasks_body = cls(
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            title=title,
            ecosystem_id=ecosystem_id,
            description=description,
            is_completed=is_completed,
            priority=priority,
            due_date=due_date,
            due_datetime=due_datetime,
            external_project_id=external_project_id,
            external_project_name=external_project_name,
            labels=labels,
            url=url,
        )

        return post_v1_tasks_body
