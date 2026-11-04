from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostIntegrationIntegrationSocialNotificationsBody")


@_attrs_define
class PostIntegrationIntegrationSocialNotificationsBody:
    """
    Attributes:
        connection_id (str):
        external_id (str):
        source_provider (str):
        notification_type (str):
        ecosystem_id (str | Unset):
        title (None | str | Unset):
        body (None | str | Unset):
        author_handle (None | str | Unset):
        author_display_name (None | str | Unset):
        item_url (None | str | Unset):
        is_read (bool | Unset):
        external_created_at (None | str | Unset):
    """

    connection_id: str
    external_id: str
    source_provider: str
    notification_type: str
    ecosystem_id: str | Unset = UNSET
    title: None | str | Unset = UNSET
    body: None | str | Unset = UNSET
    author_handle: None | str | Unset = UNSET
    author_display_name: None | str | Unset = UNSET
    item_url: None | str | Unset = UNSET
    is_read: bool | Unset = UNSET
    external_created_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        connection_id = self.connection_id

        external_id = self.external_id

        source_provider = self.source_provider

        notification_type = self.notification_type

        ecosystem_id = self.ecosystem_id

        title: None | str | Unset
        if isinstance(self.title, Unset):
            title = UNSET
        else:
            title = self.title

        body: None | str | Unset
        if isinstance(self.body, Unset):
            body = UNSET
        else:
            body = self.body

        author_handle: None | str | Unset
        if isinstance(self.author_handle, Unset):
            author_handle = UNSET
        else:
            author_handle = self.author_handle

        author_display_name: None | str | Unset
        if isinstance(self.author_display_name, Unset):
            author_display_name = UNSET
        else:
            author_display_name = self.author_display_name

        item_url: None | str | Unset
        if isinstance(self.item_url, Unset):
            item_url = UNSET
        else:
            item_url = self.item_url

        is_read = self.is_read

        external_created_at: None | str | Unset
        if isinstance(self.external_created_at, Unset):
            external_created_at = UNSET
        else:
            external_created_at = self.external_created_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "connectionId": connection_id,
                "externalId": external_id,
                "sourceProvider": source_provider,
                "notificationType": notification_type,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if title is not UNSET:
            field_dict["title"] = title
        if body is not UNSET:
            field_dict["body"] = body
        if author_handle is not UNSET:
            field_dict["authorHandle"] = author_handle
        if author_display_name is not UNSET:
            field_dict["authorDisplayName"] = author_display_name
        if item_url is not UNSET:
            field_dict["itemUrl"] = item_url
        if is_read is not UNSET:
            field_dict["isRead"] = is_read
        if external_created_at is not UNSET:
            field_dict["externalCreatedAt"] = external_created_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        connection_id = d.pop("connectionId")

        external_id = d.pop("externalId")

        source_provider = d.pop("sourceProvider")

        notification_type = d.pop("notificationType")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_title(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        title = _parse_title(d.pop("title", UNSET))

        def _parse_body(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        body = _parse_body(d.pop("body", UNSET))

        def _parse_author_handle(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_handle = _parse_author_handle(d.pop("authorHandle", UNSET))

        def _parse_author_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_display_name = _parse_author_display_name(d.pop("authorDisplayName", UNSET))

        def _parse_item_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        item_url = _parse_item_url(d.pop("itemUrl", UNSET))

        is_read = d.pop("isRead", UNSET)

        def _parse_external_created_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        external_created_at = _parse_external_created_at(d.pop("externalCreatedAt", UNSET))

        post_integration_integration_social_notifications_body = cls(
            connection_id=connection_id,
            external_id=external_id,
            source_provider=source_provider,
            notification_type=notification_type,
            ecosystem_id=ecosystem_id,
            title=title,
            body=body,
            author_handle=author_handle,
            author_display_name=author_display_name,
            item_url=item_url,
            is_read=is_read,
            external_created_at=external_created_at,
        )

        return post_integration_integration_social_notifications_body
