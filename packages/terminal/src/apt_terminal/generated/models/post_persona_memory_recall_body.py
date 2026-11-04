from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_persona_memory_recall_body_memory_type import (
    PostPersonaMemoryRecallBodyMemoryType,
)
from ..models.post_persona_memory_recall_body_mode import PostPersonaMemoryRecallBodyMode
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaMemoryRecallBody")


@_attrs_define
class PostPersonaMemoryRecallBody:
    """
    Attributes:
        persona_id (str):
        query (str):
        limit (int | Unset):
        memory_type (PostPersonaMemoryRecallBodyMemoryType | Unset):
        mode (PostPersonaMemoryRecallBodyMode | Unset): `keyword` needs no embedder; `semantic` fails with 503/502 when
            it cannot embed; `combined` falls back to keyword hits alone Default: PostPersonaMemoryRecallBodyMode.COMBINED.
    """

    persona_id: str
    query: str
    limit: int | Unset = UNSET
    memory_type: PostPersonaMemoryRecallBodyMemoryType | Unset = UNSET
    mode: PostPersonaMemoryRecallBodyMode | Unset = PostPersonaMemoryRecallBodyMode.COMBINED
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        persona_id = self.persona_id

        query = self.query

        limit = self.limit

        memory_type: str | Unset = UNSET
        if not isinstance(self.memory_type, Unset):
            memory_type = self.memory_type.value

        mode: str | Unset = UNSET
        if not isinstance(self.mode, Unset):
            mode = self.mode.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "personaId": persona_id,
                "query": query,
            }
        )
        if limit is not UNSET:
            field_dict["limit"] = limit
        if memory_type is not UNSET:
            field_dict["memoryType"] = memory_type
        if mode is not UNSET:
            field_dict["mode"] = mode

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        persona_id = d.pop("personaId")

        query = d.pop("query")

        limit = d.pop("limit", UNSET)

        _memory_type = d.pop("memoryType", UNSET)
        memory_type: PostPersonaMemoryRecallBodyMemoryType | Unset
        if isinstance(_memory_type, Unset):
            memory_type = UNSET
        else:
            memory_type = PostPersonaMemoryRecallBodyMemoryType(_memory_type)

        _mode = d.pop("mode", UNSET)
        mode: PostPersonaMemoryRecallBodyMode | Unset
        if isinstance(_mode, Unset):
            mode = UNSET
        else:
            mode = PostPersonaMemoryRecallBodyMode(_mode)

        post_persona_memory_recall_body = cls(
            persona_id=persona_id,
            query=query,
            limit=limit,
            memory_type=memory_type,
            mode=mode,
        )

        post_persona_memory_recall_body.additional_properties = d
        return post_persona_memory_recall_body

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
