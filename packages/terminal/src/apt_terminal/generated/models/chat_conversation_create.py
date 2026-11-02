from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ChatConversationCreate")


@_attrs_define
class ChatConversationCreate:
    """
    Attributes:
        title (str | Unset):
        model (str | Unset):
        persona_slug (str | Unset):
    """

    title: str | Unset = UNSET
    model: str | Unset = UNSET
    persona_slug: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        model = self.model

        persona_slug = self.persona_slug

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if title is not UNSET:
            field_dict["title"] = title
        if model is not UNSET:
            field_dict["model"] = model
        if persona_slug is not UNSET:
            field_dict["personaSlug"] = persona_slug

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title", UNSET)

        model = d.pop("model", UNSET)

        persona_slug = d.pop("personaSlug", UNSET)

        chat_conversation_create = cls(
            title=title,
            model=model,
            persona_slug=persona_slug,
        )

        chat_conversation_create.additional_properties = d
        return chat_conversation_create

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
