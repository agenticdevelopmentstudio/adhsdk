from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentsByIdResponse200")


@_attrs_define
class PostV1DocumentsByIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        title (str):
        doc_type (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        last_op_id (None | str):
        last_snapshot_id (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['document'] | Unset):
    """

    id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    title: str
    doc_type: str
    created: int
    updated: int
    is_deleted: bool
    last_op_id: None | str
    last_snapshot_id: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["document"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        title = self.title

        doc_type = self.doc_type

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        last_op_id: None | str
        last_op_id = self.last_op_id

        last_snapshot_id: None | str
        last_snapshot_id = self.last_snapshot_id

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
                "title": title,
                "doc_type": doc_type,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "last_op_id": last_op_id,
                "last_snapshot_id": last_snapshot_id,
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

        title = d.pop("title")

        doc_type = d.pop("doc_type")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        def _parse_last_op_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_op_id = _parse_last_op_id(d.pop("last_op_id"))

        def _parse_last_snapshot_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_snapshot_id = _parse_last_snapshot_id(d.pop("last_snapshot_id"))

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["document"] | Unset, d.pop("object", UNSET))
        if object_ != "document" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'document', got '{object_}'")

        post_v1_documents_by_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            title=title,
            doc_type=doc_type,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            last_op_id=last_op_id,
            last_snapshot_id=last_snapshot_id,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_documents_by_id_response_200
