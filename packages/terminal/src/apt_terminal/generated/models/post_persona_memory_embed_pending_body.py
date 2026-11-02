from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaMemoryEmbedPendingBody")


@_attrs_define
class PostPersonaMemoryEmbedPendingBody:
    """
    Attributes:
        persona_id (str | Unset):
        limit (int | Unset):
    """

    persona_id: str | Unset = UNSET
    limit: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        persona_id = self.persona_id

        limit = self.limit

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if persona_id is not UNSET:
            field_dict["personaId"] = persona_id
        if limit is not UNSET:
            field_dict["limit"] = limit

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        persona_id = d.pop("personaId", UNSET)

        limit = d.pop("limit", UNSET)

        post_persona_memory_embed_pending_body = cls(
            persona_id=persona_id,
            limit=limit,
        )

        post_persona_memory_embed_pending_body.additional_properties = d
        return post_persona_memory_embed_pending_body

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
