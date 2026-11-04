from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_memory_match_memory_type import PersonaMemoryMatchMemoryType
from ..models.persona_memory_match_scope import PersonaMemoryMatchScope

T = TypeVar("T", bound="PersonaMemoryMatch")


@_attrs_define
class PersonaMemoryMatch:
    """
    Attributes:
        id (str):
        persona_id (str):
        scope (PersonaMemoryMatchScope):
        slug (str):
        memory_type (PersonaMemoryMatchMemoryType):
        description (str):
        body (str):
        confidence (int):
        tags (list[str]):
        similarity (float | None): Cosine similarity, negatives clamped to 0; null for a keyword hit
    """

    id: str
    persona_id: str
    scope: PersonaMemoryMatchScope
    slug: str
    memory_type: PersonaMemoryMatchMemoryType
    description: str
    body: str
    confidence: int
    tags: list[str]
    similarity: float | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        persona_id = self.persona_id

        scope = self.scope.value

        slug = self.slug

        memory_type = self.memory_type.value

        description = self.description

        body = self.body

        confidence = self.confidence

        tags = self.tags

        similarity: float | None
        similarity = self.similarity

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "personaId": persona_id,
                "scope": scope,
                "slug": slug,
                "memoryType": memory_type,
                "description": description,
                "body": body,
                "confidence": confidence,
                "tags": tags,
                "similarity": similarity,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        persona_id = d.pop("personaId")

        scope = PersonaMemoryMatchScope(d.pop("scope"))

        slug = d.pop("slug")

        memory_type = PersonaMemoryMatchMemoryType(d.pop("memoryType"))

        description = d.pop("description")

        body = d.pop("body")

        confidence = d.pop("confidence")

        tags = cast(list[str], d.pop("tags"))

        def _parse_similarity(data: object) -> float | None:
            if data is None:
                return data
            return cast(float | None, data)

        similarity = _parse_similarity(d.pop("similarity"))

        persona_memory_match = cls(
            id=id,
            persona_id=persona_id,
            scope=scope,
            slug=slug,
            memory_type=memory_type,
            description=description,
            body=body,
            confidence=confidence,
            tags=tags,
            similarity=similarity,
        )

        persona_memory_match.additional_properties = d
        return persona_memory_match

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
