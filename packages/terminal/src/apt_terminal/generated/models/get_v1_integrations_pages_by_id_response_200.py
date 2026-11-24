from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1IntegrationsPagesByIdResponse200")


@_attrs_define
class GetV1IntegrationsPagesByIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['integrations.page'] | Unset):
    """

    id: str
    owner_kind: str
    owner_id: str
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
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["integrations.page"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

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
                "title": title,
                "object_type": object_type,
                "url": url,
                "icon": icon,
                "parent_type": parent_type,
                "parent_id": parent_id,
                "is_archived": is_archived,
                "last_edited_at": last_edited_at,
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

        title = d.pop("title")

        object_type = d.pop("object_type")

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

        parent_type = _parse_parent_type(d.pop("parent_type"))

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parent_id"))

        is_archived = d.pop("is_archived")

        def _parse_last_edited_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_edited_at = _parse_last_edited_at(d.pop("last_edited_at"))

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

        object_ = cast(Literal["integrations.page"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.page" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'integrations.page', got '{object_}'")

        get_v1_integrations_pages_by_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
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
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_integrations_pages_by_id_response_200
