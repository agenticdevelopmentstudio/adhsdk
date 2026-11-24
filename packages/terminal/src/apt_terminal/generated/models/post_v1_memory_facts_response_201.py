from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MemoryFactsResponse201")


@_attrs_define
class PostV1MemoryFactsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        persona_id (UUID):
        scope (str):
        memory_id (None | str):
        subject_table (None | str):
        subject_id (None | str):
        predicate (str):
        object_table (None | str):
        object_id (None | str):
        object_value (None | str):
        source (str):
        confidence (int):
        valid_from (None | str):
        valid_to (None | str):
        status (str):
        supersedes_id (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['memory_fact'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    persona_id: UUID
    scope: str
    memory_id: None | str
    subject_table: None | str
    subject_id: None | str
    predicate: str
    object_table: None | str
    object_id: None | str
    object_value: None | str
    source: str
    confidence: int
    valid_from: None | str
    valid_to: None | str
    status: str
    supersedes_id: None | str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["memory_fact"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        persona_id = str(self.persona_id)

        scope = self.scope

        memory_id: None | str
        memory_id = self.memory_id

        subject_table: None | str
        subject_table = self.subject_table

        subject_id: None | str
        subject_id = self.subject_id

        predicate = self.predicate

        object_table: None | str
        object_table = self.object_table

        object_id: None | str
        object_id = self.object_id

        object_value: None | str
        object_value = self.object_value

        source = self.source

        confidence = self.confidence

        valid_from: None | str
        valid_from = self.valid_from

        valid_to: None | str
        valid_to = self.valid_to

        status = self.status

        supersedes_id: None | str
        supersedes_id = self.supersedes_id

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
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "persona_id": persona_id,
                "scope": scope,
                "memory_id": memory_id,
                "subject_table": subject_table,
                "subject_id": subject_id,
                "predicate": predicate,
                "object_table": object_table,
                "object_id": object_id,
                "object_value": object_value,
                "source": source,
                "confidence": confidence,
                "valid_from": valid_from,
                "valid_to": valid_to,
                "status": status,
                "supersedes_id": supersedes_id,
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

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        persona_id = UUID(d.pop("persona_id"))

        scope = d.pop("scope")

        def _parse_memory_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        memory_id = _parse_memory_id(d.pop("memory_id"))

        def _parse_subject_table(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_table = _parse_subject_table(d.pop("subject_table"))

        def _parse_subject_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_id = _parse_subject_id(d.pop("subject_id"))

        predicate = d.pop("predicate")

        def _parse_object_table(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_table = _parse_object_table(d.pop("object_table"))

        def _parse_object_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_id = _parse_object_id(d.pop("object_id"))

        def _parse_object_value(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_value = _parse_object_value(d.pop("object_value"))

        source = d.pop("source")

        confidence = d.pop("confidence")

        def _parse_valid_from(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        valid_from = _parse_valid_from(d.pop("valid_from"))

        def _parse_valid_to(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        valid_to = _parse_valid_to(d.pop("valid_to"))

        status = d.pop("status")

        def _parse_supersedes_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedes_id"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["memory_fact"] | Unset, d.pop("object", UNSET))
        if object_ != "memory_fact" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'memory_fact', got '{object_}'")

        post_v1_memory_facts_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            persona_id=persona_id,
            scope=scope,
            memory_id=memory_id,
            subject_table=subject_table,
            subject_id=subject_id,
            predicate=predicate,
            object_table=object_table,
            object_id=object_id,
            object_value=object_value,
            source=source,
            confidence=confidence,
            valid_from=valid_from,
            valid_to=valid_to,
            status=status,
            supersedes_id=supersedes_id,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_memory_facts_response_201
