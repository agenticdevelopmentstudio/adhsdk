from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1DocumentOperationsResponse201")


@_attrs_define
class PostV1DocumentOperationsResponse201:
    """
    Attributes:
        id (str):
        document_id (str):
        block_id (None | str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        client_id (str):
        client_seq (int):
        op_type (str):
        op_payload (str):
        created (int): Unix timestamp, in seconds.
        undo_group_id (None | str):
        inverse_of_op_id (None | str):
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['document_operation'] | Unset):
    """

    id: str
    document_id: str
    block_id: None | str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    client_id: str
    client_seq: int
    op_type: str
    op_payload: str
    created: int
    undo_group_id: None | str
    inverse_of_op_id: None | str
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["document_operation"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        document_id = self.document_id

        block_id: None | str
        block_id = self.block_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        client_id = self.client_id

        client_seq = self.client_seq

        op_type = self.op_type

        op_payload = self.op_payload

        created = self.created

        undo_group_id: None | str
        undo_group_id = self.undo_group_id

        inverse_of_op_id: None | str
        inverse_of_op_id = self.inverse_of_op_id

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
                "document_id": document_id,
                "block_id": block_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "client_id": client_id,
                "client_seq": client_seq,
                "op_type": op_type,
                "op_payload": op_payload,
                "created": created,
                "undo_group_id": undo_group_id,
                "inverse_of_op_id": inverse_of_op_id,
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

        document_id = d.pop("document_id")

        def _parse_block_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        block_id = _parse_block_id(d.pop("block_id"))

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        client_id = d.pop("client_id")

        client_seq = d.pop("client_seq")

        op_type = d.pop("op_type")

        op_payload = d.pop("op_payload")

        created = d.pop("created")

        def _parse_undo_group_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        undo_group_id = _parse_undo_group_id(d.pop("undo_group_id"))

        def _parse_inverse_of_op_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        inverse_of_op_id = _parse_inverse_of_op_id(d.pop("inverse_of_op_id"))

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["document_operation"] | Unset, d.pop("object", UNSET))
        if object_ != "document_operation" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'document_operation', got '{object_}'")

        post_v1_document_operations_response_201 = cls(
            id=id,
            document_id=document_id,
            block_id=block_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            client_id=client_id,
            client_seq=client_seq,
            op_type=op_type,
            op_payload=op_payload,
            created=created,
            undo_group_id=undo_group_id,
            inverse_of_op_id=inverse_of_op_id,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_document_operations_response_201
