from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsPagesByIdBody")


@_attrs_define
class PostV1IntegrationsPagesByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        connection_id (str | Unset):
        external_id (str | Unset):
        title (str | Unset):
        object_type (str | Unset):
        url (None | str | Unset):
        icon (None | str | Unset):
        parent_type (None | str | Unset):
        parent_id (None | str | Unset):
        is_archived (bool | Unset):
        last_edited_at (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    connection_id: str | Unset = UNSET
    external_id: str | Unset = UNSET
    title: str | Unset = UNSET
    object_type: str | Unset = UNSET
    url: None | str | Unset = UNSET
    icon: None | str | Unset = UNSET
    parent_type: None | str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    is_archived: bool | Unset = UNSET
    last_edited_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        external_id = self.external_id

        title = self.title

        object_type = self.object_type

        url: None | str | Unset
        if isinstance(self.url, Unset):
            url = UNSET
        else:
            url = self.url

        icon: None | str | Unset
        if isinstance(self.icon, Unset):
            icon = UNSET
        else:
            icon = self.icon

        parent_type: None | str | Unset
        if isinstance(self.parent_type, Unset):
            parent_type = UNSET
        else:
            parent_type = self.parent_type

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        is_archived = self.is_archived

        last_edited_at: None | str | Unset
        if isinstance(self.last_edited_at, Unset):
            last_edited_at = UNSET
        else:
            last_edited_at = self.last_edited_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if external_id is not UNSET:
            field_dict["external_id"] = external_id
        if title is not UNSET:
            field_dict["title"] = title
        if object_type is not UNSET:
            field_dict["object_type"] = object_type
        if url is not UNSET:
            field_dict["url"] = url
        if icon is not UNSET:
            field_dict["icon"] = icon
        if parent_type is not UNSET:
            field_dict["parent_type"] = parent_type
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if is_archived is not UNSET:
            field_dict["is_archived"] = is_archived
        if last_edited_at is not UNSET:
            field_dict["last_edited_at"] = last_edited_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        connection_id = d.pop("connection_id", UNSET)

        external_id = d.pop("external_id", UNSET)

        title = d.pop("title", UNSET)

        object_type = d.pop("object_type", UNSET)

        def _parse_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        url = _parse_url(d.pop("url", UNSET))

        def _parse_icon(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        icon = _parse_icon(d.pop("icon", UNSET))

        def _parse_parent_type(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_type = _parse_parent_type(d.pop("parent_type", UNSET))

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

        is_archived = d.pop("is_archived", UNSET)

        def _parse_last_edited_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_edited_at = _parse_last_edited_at(d.pop("last_edited_at", UNSET))

        post_v1_integrations_pages_by_id_body = cls(
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
        )

        return post_v1_integrations_pages_by_id_body
