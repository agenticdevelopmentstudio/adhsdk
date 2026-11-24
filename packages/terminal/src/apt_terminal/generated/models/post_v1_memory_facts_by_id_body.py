from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MemoryFactsByIdBody")


@_attrs_define
class PostV1MemoryFactsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        persona_id (UUID | Unset):
        scope (str | Unset):
        memory_id (None | str | Unset):
        subject_table (None | str | Unset):
        subject_id (None | str | Unset):
        predicate (str | Unset):
        object_table (None | str | Unset):
        object_id (None | str | Unset):
        object_value (None | str | Unset):
        source (str | Unset):
        confidence (int | Unset):
        valid_from (None | str | Unset):
        valid_to (None | str | Unset):
        status (str | Unset):
        supersedes_id (None | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    persona_id: UUID | Unset = UNSET
    scope: str | Unset = UNSET
    memory_id: None | str | Unset = UNSET
    subject_table: None | str | Unset = UNSET
    subject_id: None | str | Unset = UNSET
    predicate: str | Unset = UNSET
    object_table: None | str | Unset = UNSET
    object_id: None | str | Unset = UNSET
    object_value: None | str | Unset = UNSET
    source: str | Unset = UNSET
    confidence: int | Unset = UNSET
    valid_from: None | str | Unset = UNSET
    valid_to: None | str | Unset = UNSET
    status: str | Unset = UNSET
    supersedes_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        persona_id: str | Unset = UNSET
        if not isinstance(self.persona_id, Unset):
            persona_id = str(self.persona_id)

        scope = self.scope

        memory_id: None | str | Unset
        if isinstance(self.memory_id, Unset):
            memory_id = UNSET
        else:
            memory_id = self.memory_id

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

        predicate = self.predicate

        object_table: None | str | Unset
        if isinstance(self.object_table, Unset):
            object_table = UNSET
        else:
            object_table = self.object_table

        object_id: None | str | Unset
        if isinstance(self.object_id, Unset):
            object_id = UNSET
        else:
            object_id = self.object_id

        object_value: None | str | Unset
        if isinstance(self.object_value, Unset):
            object_value = UNSET
        else:
            object_value = self.object_value

        source = self.source

        confidence = self.confidence

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

        status = self.status

        supersedes_id: None | str | Unset
        if isinstance(self.supersedes_id, Unset):
            supersedes_id = UNSET
        else:
            supersedes_id = self.supersedes_id

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if persona_id is not UNSET:
            field_dict["persona_id"] = persona_id
        if scope is not UNSET:
            field_dict["scope"] = scope
        if memory_id is not UNSET:
            field_dict["memory_id"] = memory_id
        if subject_table is not UNSET:
            field_dict["subject_table"] = subject_table
        if subject_id is not UNSET:
            field_dict["subject_id"] = subject_id
        if predicate is not UNSET:
            field_dict["predicate"] = predicate
        if object_table is not UNSET:
            field_dict["object_table"] = object_table
        if object_id is not UNSET:
            field_dict["object_id"] = object_id
        if object_value is not UNSET:
            field_dict["object_value"] = object_value
        if source is not UNSET:
            field_dict["source"] = source
        if confidence is not UNSET:
            field_dict["confidence"] = confidence
        if valid_from is not UNSET:
            field_dict["valid_from"] = valid_from
        if valid_to is not UNSET:
            field_dict["valid_to"] = valid_to
        if status is not UNSET:
            field_dict["status"] = status
        if supersedes_id is not UNSET:
            field_dict["supersedes_id"] = supersedes_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        _persona_id = d.pop("persona_id", UNSET)
        persona_id: UUID | Unset
        if isinstance(_persona_id, Unset):
            persona_id = UNSET
        else:
            persona_id = UUID(_persona_id)

        scope = d.pop("scope", UNSET)

        def _parse_memory_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        memory_id = _parse_memory_id(d.pop("memory_id", UNSET))

        def _parse_subject_table(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_table = _parse_subject_table(d.pop("subject_table", UNSET))

        def _parse_subject_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_id = _parse_subject_id(d.pop("subject_id", UNSET))

        predicate = d.pop("predicate", UNSET)

        def _parse_object_table(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        object_table = _parse_object_table(d.pop("object_table", UNSET))

        def _parse_object_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        object_id = _parse_object_id(d.pop("object_id", UNSET))

        def _parse_object_value(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        object_value = _parse_object_value(d.pop("object_value", UNSET))

        source = d.pop("source", UNSET)

        confidence = d.pop("confidence", UNSET)

        def _parse_valid_from(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        valid_from = _parse_valid_from(d.pop("valid_from", UNSET))

        def _parse_valid_to(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        valid_to = _parse_valid_to(d.pop("valid_to", UNSET))

        status = d.pop("status", UNSET)

        def _parse_supersedes_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedes_id", UNSET))

        post_v1_memory_facts_by_id_body = cls(
            ecosystem_id=ecosystem_id,
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
        )

        return post_v1_memory_facts_by_id_body
