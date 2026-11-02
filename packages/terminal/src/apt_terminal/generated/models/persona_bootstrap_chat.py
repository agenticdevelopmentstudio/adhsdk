from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_bootstrap_chat_streaming import PersonaBootstrapChatStreaming

if TYPE_CHECKING:
    from ..models.persona_bootstrap_chat_limits import PersonaBootstrapChatLimits


T = TypeVar("T", bound="PersonaBootstrapChat")


@_attrs_define
class PersonaBootstrapChat:
    """
    Attributes:
        conversations_url (str): Where to open conversations — the public visitor surface or the authenticated one
        streaming (PersonaBootstrapChatStreaming):
        limits (PersonaBootstrapChatLimits):
    """

    conversations_url: str
    streaming: PersonaBootstrapChatStreaming
    limits: PersonaBootstrapChatLimits
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        conversations_url = self.conversations_url

        streaming = self.streaming.value

        limits = self.limits.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "conversationsUrl": conversations_url,
                "streaming": streaming,
                "limits": limits,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_bootstrap_chat_limits import (
            PersonaBootstrapChatLimits,
        )

        d = dict(src_dict)
        conversations_url = d.pop("conversationsUrl")

        streaming = PersonaBootstrapChatStreaming(d.pop("streaming"))

        limits = PersonaBootstrapChatLimits.from_dict(d.pop("limits"))

        persona_bootstrap_chat = cls(
            conversations_url=conversations_url,
            streaming=streaming,
            limits=limits,
        )

        persona_bootstrap_chat.additional_properties = d
        return persona_bootstrap_chat

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
