from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_persona_memory_global_body_memory_type import (
    PostPersonaMemoryGlobalBodyMemoryType,
)
from ..models.post_persona_memory_global_body_source import PostPersonaMemoryGlobalBodySource
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaMemoryGlobalBody")


@_attrs_define
class PostPersonaMemoryGlobalBody:
    """
    Attributes:
        persona_id (str):
        slug (str):
        memory_type (PostPersonaMemoryGlobalBodyMemoryType):
        description (str):
        body (str):
        subject_table (str | Unset):
        subject_id (str | Unset):
        source (PostPersonaMemoryGlobalBodySource | Unset):
        confidence (int | Unset):
        tags (list[str] | Unset):
    """

    persona_id: str
    slug: str
    memory_type: PostPersonaMemoryGlobalBodyMemoryType
    description: str
    body: str
    subject_table: str | Unset = UNSET
    subject_id: str | Unset = UNSET
    source: PostPersonaMemoryGlobalBodySource | Unset = UNSET
    confidence: int | Unset = UNSET
    tags: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        persona_id = self.persona_id

        slug = self.slug

        memory_type = self.memory_type.value

        description = self.description

        body = self.body

        subject_table = self.subject_table

        subject_id = self.subject_id

        source: str | Unset = UNSET
        if not isinstance(self.source, Unset):
            source = self.source.value

        confidence = self.confidence

        tags: list[str] | Unset = UNSET
        if not isinstance(self.tags, Unset):
            tags = self.tags

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "personaId": persona_id,
                "slug": slug,
                "memoryType": memory_type,
                "description": description,
                "body": body,
            }
        )
        if subject_table is not UNSET:
            field_dict["subjectTable"] = subject_table
        if subject_id is not UNSET:
            field_dict["subjectId"] = subject_id
        if source is not UNSET:
            field_dict["source"] = source
        if confidence is not UNSET:
            field_dict["confidence"] = confidence
        if tags is not UNSET:
            field_dict["tags"] = tags

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        persona_id = d.pop("personaId")

        slug = d.pop("slug")

        memory_type = PostPersonaMemoryGlobalBodyMemoryType(d.pop("memoryType"))

        description = d.pop("description")

        body = d.pop("body")

        subject_table = d.pop("subjectTable", UNSET)

        subject_id = d.pop("subjectId", UNSET)

        _source = d.pop("source", UNSET)
        source: PostPersonaMemoryGlobalBodySource | Unset
        if isinstance(_source, Unset):
            source = UNSET
        else:
            source = PostPersonaMemoryGlobalBodySource(_source)

        confidence = d.pop("confidence", UNSET)

        tags = cast(list[str], d.pop("tags", UNSET))

        post_persona_memory_global_body = cls(
            persona_id=persona_id,
            slug=slug,
            memory_type=memory_type,
            description=description,
            body=body,
            subject_table=subject_table,
            subject_id=subject_id,
            source=source,
            confidence=confidence,
            tags=tags,
        )

        post_persona_memory_global_body.additional_properties = d
        return post_persona_memory_global_body

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
