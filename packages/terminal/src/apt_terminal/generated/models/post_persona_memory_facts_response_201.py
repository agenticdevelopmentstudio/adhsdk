from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostPersonaMemoryFactsResponse201")


@_attrs_define
class PostPersonaMemoryFactsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
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
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    customer_id: str
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
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

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

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "personaId": persona_id,
                "scope": scope,
                "memoryId": memory_id,
                "subjectTable": subject_table,
                "subjectId": subject_id,
                "predicate": predicate,
                "objectTable": object_table,
                "objectId": object_id,
                "objectValue": object_value,
                "source": source,
                "confidence": confidence,
                "validFrom": valid_from,
                "validTo": valid_to,
                "status": status,
                "supersedesId": supersedes_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        persona_id = UUID(d.pop("personaId"))

        scope = d.pop("scope")

        def _parse_memory_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        memory_id = _parse_memory_id(d.pop("memoryId"))

        def _parse_subject_table(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_table = _parse_subject_table(d.pop("subjectTable"))

        def _parse_subject_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject_id = _parse_subject_id(d.pop("subjectId"))

        predicate = d.pop("predicate")

        def _parse_object_table(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_table = _parse_object_table(d.pop("objectTable"))

        def _parse_object_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_id = _parse_object_id(d.pop("objectId"))

        def _parse_object_value(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        object_value = _parse_object_value(d.pop("objectValue"))

        source = d.pop("source")

        confidence = d.pop("confidence")

        def _parse_valid_from(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        valid_from = _parse_valid_from(d.pop("validFrom"))

        def _parse_valid_to(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        valid_to = _parse_valid_to(d.pop("validTo"))

        status = d.pop("status")

        def _parse_supersedes_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedesId"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        post_persona_memory_facts_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
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
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_persona_memory_facts_response_201
