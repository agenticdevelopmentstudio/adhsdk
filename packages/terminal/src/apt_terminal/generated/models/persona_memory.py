from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_memory_memory_type import PersonaMemoryMemoryType
from ..models.persona_memory_scope import PersonaMemoryScope
from ..models.persona_memory_source import PersonaMemorySource
from ..models.persona_memory_status import PersonaMemoryStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PersonaMemory")


@_attrs_define
class PersonaMemory:
    """
    Attributes:
        id (str):
        ecosystem_id (str): Ecosystem (tenant) id
        customer_id (str): Owning user; empty for a global memory
        persona_id (str):
        scope (PersonaMemoryScope):
        slug (str):
        memory_type (PersonaMemoryMemoryType):
        description (str):
        body (str):
        status (PersonaMemoryStatus):
        source (PersonaMemorySource):
        confidence (int):
        tags (list[str]):
        recall_count (int):
        created_at (str):
        updated_at (str):
        deleted_at (None | str | Unset):
        subject_table (None | str | Unset):
        subject_id (None | str | Unset):
        supersedes_id (None | str | Unset):
        valid_from (None | str | Unset):
        valid_to (None | str | Unset):
        last_recalled_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    persona_id: str
    scope: PersonaMemoryScope
    slug: str
    memory_type: PersonaMemoryMemoryType
    description: str
    body: str
    status: PersonaMemoryStatus
    source: PersonaMemorySource
    confidence: int
    tags: list[str]
    recall_count: int
    created_at: str
    updated_at: str
    deleted_at: None | str | Unset = UNSET
    subject_table: None | str | Unset = UNSET
    subject_id: None | str | Unset = UNSET
    supersedes_id: None | str | Unset = UNSET
    valid_from: None | str | Unset = UNSET
    valid_to: None | str | Unset = UNSET
    last_recalled_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        persona_id = self.persona_id

        scope = self.scope.value

        slug = self.slug

        memory_type = self.memory_type.value

        description = self.description

        body = self.body

        status = self.status.value

        source = self.source.value

        confidence = self.confidence

        tags = self.tags

        recall_count = self.recall_count

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

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

        supersedes_id: None | str | Unset
        if isinstance(self.supersedes_id, Unset):
            supersedes_id = UNSET
        else:
            supersedes_id = self.supersedes_id

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

        last_recalled_at: None | str | Unset
        if isinstance(self.last_recalled_at, Unset):
            last_recalled_at = UNSET
        else:
            last_recalled_at = self.last_recalled_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "customerId": customer_id,
                "personaId": persona_id,
                "scope": scope,
                "slug": slug,
                "memoryType": memory_type,
                "description": description,
                "body": body,
                "status": status,
                "source": source,
                "confidence": confidence,
                "tags": tags,
                "recallCount": recall_count,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at
        if subject_table is not UNSET:
            field_dict["subjectTable"] = subject_table
        if subject_id is not UNSET:
            field_dict["subjectId"] = subject_id
        if supersedes_id is not UNSET:
            field_dict["supersedesId"] = supersedes_id
        if valid_from is not UNSET:
            field_dict["validFrom"] = valid_from
        if valid_to is not UNSET:
            field_dict["validTo"] = valid_to
        if last_recalled_at is not UNSET:
            field_dict["lastRecalledAt"] = last_recalled_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        persona_id = d.pop("personaId")

        scope = PersonaMemoryScope(d.pop("scope"))

        slug = d.pop("slug")

        memory_type = PersonaMemoryMemoryType(d.pop("memoryType"))

        description = d.pop("description")

        body = d.pop("body")

        status = PersonaMemoryStatus(d.pop("status"))

        source = PersonaMemorySource(d.pop("source"))

        confidence = d.pop("confidence")

        tags = cast(list[str], d.pop("tags"))

        recall_count = d.pop("recallCount")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

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

        def _parse_supersedes_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        supersedes_id = _parse_supersedes_id(d.pop("supersedesId", UNSET))

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

        def _parse_last_recalled_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_recalled_at = _parse_last_recalled_at(d.pop("lastRecalledAt", UNSET))

        persona_memory = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            persona_id=persona_id,
            scope=scope,
            slug=slug,
            memory_type=memory_type,
            description=description,
            body=body,
            status=status,
            source=source,
            confidence=confidence,
            tags=tags,
            recall_count=recall_count,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            subject_table=subject_table,
            subject_id=subject_id,
            supersedes_id=supersedes_id,
            valid_from=valid_from,
            valid_to=valid_to,
            last_recalled_at=last_recalled_at,
        )

        persona_memory.additional_properties = d
        return persona_memory

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
