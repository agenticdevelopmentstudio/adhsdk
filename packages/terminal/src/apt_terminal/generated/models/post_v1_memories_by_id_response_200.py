from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MemoriesByIdResponse200")


@_attrs_define
class PostV1MemoriesByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        persona_id (UUID):
        scope (str):
        slug (str):
        memory_type (str):
        description (str):
        body (str):
        subject_table (None | str):
        subject_id (None | str):
        status (str):
        supersedes_id (None | str):
        source (str):
        confidence (int):
        tags (list[str]):
        valid_from (None | str):
        valid_to (None | str):
        recall_count (int):
        last_recalled_at (None | str):
        semantic_embedding (list[float] | None):
        semantic_stamp (None | str):
        semantic_source (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['memory'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    persona_id: UUID
    scope: str
    slug: str
    memory_type: str
    description: str
    body: str
    subject_table: None | str
    subject_id: None | str
    status: str
    supersedes_id: None | str
    source: str
    confidence: int
    tags: list[str]
    valid_from: None | str
    valid_to: None | str
    recall_count: int
    last_recalled_at: None | str
    semantic_embedding: list[float] | None
    semantic_stamp: None | str
    semantic_source: None | str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["memory"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        persona_id = str(self.persona_id)

        scope = self.scope

        slug = self.slug

        memory_type = self.memory_type

        description = self.description

        body = self.body

        subject_table: None | str
        subject_table = self.subject_table

        subject_id: None | str
        subject_id = self.subject_id

        status = self.status

        supersedes_id: None | str
        supersedes_id = self.supersedes_id

        source = self.source

        confidence = self.confidence

        tags = self.tags

        valid_from: None | str
        valid_from = self.valid_from

        valid_to: None | str
        valid_to = self.valid_to

        recall_count = self.recall_count

        last_recalled_at: None | str
        last_recalled_at = self.last_recalled_at

        semantic_embedding: list[float] | None
        if isinstance(self.semantic_embedding, list):
            semantic_embedding = self.semantic_embedding

        else:
            semantic_embedding = self.semantic_embedding

        semantic_stamp: None | str
        semantic_stamp = self.semantic_stamp

        semantic_source: None | str
        semantic_source = self.semantic_source

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
                "slug": slug,
                "memory_type": memory_type,
                "description": description,
                "body": body,
                "subject_table": subject_table,
                "subject_id": subject_id,
                "status": status,
                "supersedes_id": supersedes_id,
                "source": source,
                "confidence": confidence,
                "tags": tags,
                "valid_from": valid_from,
                "valid_to": valid_to,
                "recall_count": recall_count,
                "last_recalled_at": last_recalled_at,
                "semantic_embedding": semantic_embedding,
                "semantic_stamp": semantic_stamp,
                "semantic_source": semantic_source,
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

        slug = d.pop("slug")

        memory_type = d.pop("memory_type")

        description = d.pop("description")

        body = d.pop("body")

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

        status = d.pop("status")

        def _parse_supersedes_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedes_id"))

        source = d.pop("source")

        confidence = d.pop("confidence")

        tags = cast(list[str], d.pop("tags"))

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

        recall_count = d.pop("recall_count")

        def _parse_last_recalled_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_recalled_at = _parse_last_recalled_at(d.pop("last_recalled_at"))

        def _parse_semantic_embedding(data: object) -> list[float] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                semantic_embedding_type_0 = cast(list[float], data)

                return semantic_embedding_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[float] | None, data)

        semantic_embedding = _parse_semantic_embedding(d.pop("semantic_embedding"))

        def _parse_semantic_stamp(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        semantic_stamp = _parse_semantic_stamp(d.pop("semantic_stamp"))

        def _parse_semantic_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        semantic_source = _parse_semantic_source(d.pop("semantic_source"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["memory"] | Unset, d.pop("object", UNSET))
        if object_ != "memory" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'memory', got '{object_}'")

        post_v1_memories_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            persona_id=persona_id,
            scope=scope,
            slug=slug,
            memory_type=memory_type,
            description=description,
            body=body,
            subject_table=subject_table,
            subject_id=subject_id,
            status=status,
            supersedes_id=supersedes_id,
            source=source,
            confidence=confidence,
            tags=tags,
            valid_from=valid_from,
            valid_to=valid_to,
            recall_count=recall_count,
            last_recalled_at=last_recalled_at,
            semantic_embedding=semantic_embedding,
            semantic_stamp=semantic_stamp,
            semantic_source=semantic_source,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_memories_by_id_response_200
