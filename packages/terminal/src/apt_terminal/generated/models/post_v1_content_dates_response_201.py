from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentDatesResponse201")


@_attrs_define
class PostV1ContentDatesResponse201:
    """
    Attributes:
        id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        label (str):
        date (str):
        recurrence (str):
        contact_id (None | str):
        notes (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
        object_ (Literal['content.date'] | Unset):
    """

    id: str
    deleted_at: None | str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    label: str
    date: str
    recurrence: str
    contact_id: None | str
    notes: str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str
    object_: Literal["content.date"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        label = self.label

        date = self.date

        recurrence = self.recurrence

        contact_id: None | str
        contact_id = self.contact_id

        notes = self.notes

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "label": label,
                "date": date,
                "recurrence": recurrence,
                "contact_id": contact_id,
                "notes": notes,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
                "author_kind": author_kind,
                "author_id": author_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        label = d.pop("label")

        date = d.pop("date")

        recurrence = d.pop("recurrence")

        def _parse_contact_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        contact_id = _parse_contact_id(d.pop("contact_id"))

        notes = d.pop("notes")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        object_ = cast(Literal["content.date"] | Unset, d.pop("object", UNSET))
        if object_ != "content.date" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.date', got '{object_}'")

        post_v1_content_dates_response_201 = cls(
            id=id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            label=label,
            date=date,
            recurrence=recurrence,
            contact_id=contact_id,
            notes=notes,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
            object_=object_,
        )

        return post_v1_content_dates_response_201
