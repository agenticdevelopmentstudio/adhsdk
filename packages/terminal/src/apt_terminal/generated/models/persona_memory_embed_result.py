from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaMemoryEmbedResult")


@_attrs_define
class PersonaMemoryEmbedResult:
    """
    Attributes:
        embedded (int): Rows embedded this call
        failed (int): Rows that failed to embed (retried next call)
        more (bool): True if the batch filled `limit` — call again
    """

    embedded: int
    failed: int
    more: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        embedded = self.embedded

        failed = self.failed

        more = self.more

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "embedded": embedded,
                "failed": failed,
                "more": more,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        embedded = d.pop("embedded")

        failed = d.pop("failed")

        more = d.pop("more")

        persona_memory_embed_result = cls(
            embedded=embedded,
            failed=failed,
            more=more,
        )

        persona_memory_embed_result.additional_properties = d
        return persona_memory_embed_result

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
