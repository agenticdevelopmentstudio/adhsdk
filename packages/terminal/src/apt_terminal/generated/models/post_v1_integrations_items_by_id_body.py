from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsItemsByIdBody")


@_attrs_define
class PostV1IntegrationsItemsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        connection_id (str | Unset):
        external_id (str | Unset):
        item_type (str | Unset):
        title (str | Unset):
        body (None | str | Unset):
        state (str | Unset):
        repo_full_name (str | Unset):
        repo_url (None | str | Unset):
        item_url (None | str | Unset):
        number (int | None | Unset):
        labels (None | str | Unset):
        assignees (None | str | Unset):
        is_read (bool | Unset):
        notification_reason (None | str | Unset):
        external_created_at (None | str | Unset):
        external_updated_at (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    connection_id: str | Unset = UNSET
    external_id: str | Unset = UNSET
    item_type: str | Unset = UNSET
    title: str | Unset = UNSET
    body: None | str | Unset = UNSET
    state: str | Unset = UNSET
    repo_full_name: str | Unset = UNSET
    repo_url: None | str | Unset = UNSET
    item_url: None | str | Unset = UNSET
    number: int | None | Unset = UNSET
    labels: None | str | Unset = UNSET
    assignees: None | str | Unset = UNSET
    is_read: bool | Unset = UNSET
    notification_reason: None | str | Unset = UNSET
    external_created_at: None | str | Unset = UNSET
    external_updated_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        item_type = self.item_type

        title = self.title

        body: None | str | Unset
        if isinstance(self.body, Unset):
            body = UNSET
        else:
            body = self.body

        state = self.state

        repo_full_name = self.repo_full_name

        repo_url: None | str | Unset
        if isinstance(self.repo_url, Unset):
            repo_url = UNSET
        else:
            repo_url = self.repo_url

        item_url: None | str | Unset
        if isinstance(self.item_url, Unset):
            item_url = UNSET
        else:
            item_url = self.item_url

        number: int | None | Unset
        if isinstance(self.number, Unset):
            number = UNSET
        else:
            number = self.number

        labels: None | str | Unset
        if isinstance(self.labels, Unset):
            labels = UNSET
        else:
            labels = self.labels

        assignees: None | str | Unset
        if isinstance(self.assignees, Unset):
            assignees = UNSET
        else:
            assignees = self.assignees

        is_read = self.is_read

        notification_reason: None | str | Unset
        if isinstance(self.notification_reason, Unset):
            notification_reason = UNSET
        else:
            notification_reason = self.notification_reason

        external_created_at: None | str | Unset
        if isinstance(self.external_created_at, Unset):
            external_created_at = UNSET
        else:
            external_created_at = self.external_created_at

        external_updated_at: None | str | Unset
        if isinstance(self.external_updated_at, Unset):
            external_updated_at = UNSET
        else:
            external_updated_at = self.external_updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if external_id is not UNSET:
            field_dict["external_id"] = external_id
        if item_type is not UNSET:
            field_dict["item_type"] = item_type
        if title is not UNSET:
            field_dict["title"] = title
        if body is not UNSET:
            field_dict["body"] = body
        if state is not UNSET:
            field_dict["state"] = state
        if repo_full_name is not UNSET:
            field_dict["repo_full_name"] = repo_full_name
        if repo_url is not UNSET:
            field_dict["repo_url"] = repo_url
        if item_url is not UNSET:
            field_dict["item_url"] = item_url
        if number is not UNSET:
            field_dict["number"] = number
        if labels is not UNSET:
            field_dict["labels"] = labels
        if assignees is not UNSET:
            field_dict["assignees"] = assignees
        if is_read is not UNSET:
            field_dict["is_read"] = is_read
        if notification_reason is not UNSET:
            field_dict["notification_reason"] = notification_reason
        if external_created_at is not UNSET:
            field_dict["external_created_at"] = external_created_at
        if external_updated_at is not UNSET:
            field_dict["external_updated_at"] = external_updated_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        connection_id = d.pop("connection_id", UNSET)

        external_id = d.pop("external_id", UNSET)

        item_type = d.pop("item_type", UNSET)

        title = d.pop("title", UNSET)

        def _parse_body(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        body = _parse_body(d.pop("body", UNSET))

        state = d.pop("state", UNSET)

        repo_full_name = d.pop("repo_full_name", UNSET)

        def _parse_repo_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        repo_url = _parse_repo_url(d.pop("repo_url", UNSET))

        def _parse_item_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        item_url = _parse_item_url(d.pop("item_url", UNSET))

        def _parse_number(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        number = _parse_number(d.pop("number", UNSET))

        def _parse_labels(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        labels = _parse_labels(d.pop("labels", UNSET))

        def _parse_assignees(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        assignees = _parse_assignees(d.pop("assignees", UNSET))

        is_read = d.pop("is_read", UNSET)

        def _parse_notification_reason(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        notification_reason = _parse_notification_reason(d.pop("notification_reason", UNSET))

        def _parse_external_created_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_created_at = _parse_external_created_at(d.pop("external_created_at", UNSET))

        def _parse_external_updated_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_updated_at = _parse_external_updated_at(d.pop("external_updated_at", UNSET))

        post_v1_integrations_items_by_id_body = cls(
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
            external_created_at=external_created_at,
            external_updated_at=external_updated_at,
        )

        return post_v1_integrations_items_by_id_body
