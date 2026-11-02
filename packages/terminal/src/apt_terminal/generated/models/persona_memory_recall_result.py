from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.persona_memory_match import PersonaMemoryMatch


T = TypeVar("T", bound="PersonaMemoryRecallResult")


@_attrs_define
class PersonaMemoryRecallResult:
    """
    Attributes:
        memories (list[PersonaMemoryMatch]):
    """

    memories: list[PersonaMemoryMatch]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        memories = []
        for memories_item_data in self.memories:
            memories_item = memories_item_data.to_dict()
            memories.append(memories_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "memories": memories,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_memory_match import PersonaMemoryMatch

        d = dict(src_dict)
        memories = []
        _memories = d.pop("memories")
        for memories_item_data in _memories:
            memories_item = PersonaMemoryMatch.from_dict(memories_item_data)

            memories.append(memories_item)

        persona_memory_recall_result = cls(
            memories=memories,
        )

        persona_memory_recall_result.additional_properties = d
        return persona_memory_recall_result

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
