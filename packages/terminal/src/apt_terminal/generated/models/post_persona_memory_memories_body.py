from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaMemoryMemoriesBody")


@_attrs_define
class PostPersonaMemoryMemoriesBody:
    """
    Attributes:
        persona_id (UUID):
        slug (str):
        memory_type (str):
        description (str):
        body (str):
        ecosystem_id (str | Unset):
        scope (str | Unset):
        subject_table (None | str | Unset):
        subject_id (None | str | Unset):
        status (str | Unset):
        supersedes_id (None | str | Unset):
        source (str | Unset):
        confidence (int | Unset):
        tags (list[str] | Unset):
        valid_from (None | str | Unset):
        valid_to (None | str | Unset):
    """

    persona_id: UUID
    slug: str
    memory_type: str
    description: str
    body: str
    ecosystem_id: str | Unset = UNSET
    scope: str | Unset = UNSET
    subject_table: None | str | Unset = UNSET
    subject_id: None | str | Unset = UNSET
    status: str | Unset = UNSET
    supersedes_id: None | str | Unset = UNSET
    source: str | Unset = UNSET
    confidence: int | Unset = UNSET
    tags: list[str] | Unset = UNSET
    valid_from: None | str | Unset = UNSET
    valid_to: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        persona_id = str(self.persona_id)

        slug = self.slug

        memory_type = self.memory_type

        description = self.description

        body = self.body

        ecosystem_id = self.ecosystem_id

        scope = self.scope

        subject_table: None | str | Unset
        if isinstance(self.subject_table, Unset):
            subject_table = UNSET
        else:
            subject_table = self.subject_table

        subject_id: None | str | Unset
        if isinstance(self.subject_id, Unset):
            subject_id = UNSET
        else:
            subject_id = self.subject_id

        status = self.status

        supersedes_id: None | str | Unset
        if isinstance(self.supersedes_id, Unset):
            supersedes_id = UNSET
        else:
            supersedes_id = self.supersedes_id

        source = self.source

        confidence = self.confidence

        tags: list[str] | Unset = UNSET
        if not isinstance(self.tags, Unset):
            tags = self.tags

        valid_from: None | str | Unset
        if isinstance(self.valid_from, Unset):
            valid_from = UNSET
        else:
            valid_from = self.valid_from

        valid_to: None | str | Unset
        if isinstance(self.valid_to, Unset):
            valid_to = UNSET
        else:
            valid_to = self.valid_to

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "personaId": persona_id,
                "slug": slug,
                "memoryType": memory_type,
                "description": description,
                "body": body,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if scope is not UNSET:
            field_dict["scope"] = scope
        if subject_table is not UNSET:
            field_dict["subjectTable"] = subject_table
        if subject_id is not UNSET:
            field_dict["subjectId"] = subject_id
        if status is not UNSET:
            field_dict["status"] = status
        if supersedes_id is not UNSET:
            field_dict["supersedesId"] = supersedes_id
        if source is not UNSET:
            field_dict["source"] = source
        if confidence is not UNSET:
            field_dict["confidence"] = confidence
        if tags is not UNSET:
            field_dict["tags"] = tags
        if valid_from is not UNSET:
            field_dict["validFrom"] = valid_from
        if valid_to is not UNSET:
            field_dict["validTo"] = valid_to

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        persona_id = UUID(d.pop("personaId"))

        slug = d.pop("slug")

        memory_type = d.pop("memoryType")

        description = d.pop("description")

        body = d.pop("body")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        scope = d.pop("scope", UNSET)

        def _parse_subject_table(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_table = _parse_subject_table(d.pop("subjectTable", UNSET))

        def _parse_subject_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_id = _parse_subject_id(d.pop("subjectId", UNSET))

        status = d.pop("status", UNSET)

        def _parse_supersedes_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedesId", UNSET))

        source = d.pop("source", UNSET)

        confidence = d.pop("confidence", UNSET)

        tags = cast(list[str], d.pop("tags", UNSET))

        def _parse_valid_from(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        valid_from = _parse_valid_from(d.pop("validFrom", UNSET))

        def _parse_valid_to(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        valid_to = _parse_valid_to(d.pop("validTo", UNSET))

        post_persona_memory_memories_body = cls(
            persona_id=persona_id,
            slug=slug,
            memory_type=memory_type,
            description=description,
            body=body,
            ecosystem_id=ecosystem_id,
            scope=scope,
            subject_table=subject_table,
            subject_id=subject_id,
            status=status,
            supersedes_id=supersedes_id,
            source=source,
            confidence=confidence,
            tags=tags,
            valid_from=valid_from,
            valid_to=valid_to,
        )

        return post_persona_memory_memories_body
