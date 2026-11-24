from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaBootstrapChatLimits")


@_attrs_define
class PersonaBootstrapChatLimits:
    """
    Attributes:
        max_conversation_length (int):
        max_message_chars (int):
    """

    max_conversation_length: int
    max_message_chars: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        max_conversation_length = self.max_conversation_length

        max_message_chars = self.max_message_chars

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "max_conversation_length": max_conversation_length,
                "max_message_chars": max_message_chars,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        max_conversation_length = d.pop("max_conversation_length")

        max_message_chars = d.pop("max_message_chars")

        persona_bootstrap_chat_limits = cls(
            max_conversation_length=max_conversation_length,
            max_message_chars=max_message_chars,
        )

        persona_bootstrap_chat_limits.additional_properties = d
        return persona_bootstrap_chat_limits

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
