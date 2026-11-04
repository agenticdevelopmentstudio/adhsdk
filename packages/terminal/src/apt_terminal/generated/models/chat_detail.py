from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.chat import Chat
    from ..models.chat_definition import ChatDefinition


T = TypeVar("T", bound="ChatDetail")


@_attrs_define
class ChatDetail:
    """
    Attributes:
        chat (Chat):
        definition (ChatDefinition):
    """

    chat: Chat
    definition: ChatDefinition
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chat = self.chat.to_dict()

        definition = self.definition.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat": chat,
                "definition": definition,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat import Chat
        from ..models.chat_definition import ChatDefinition

        d = dict(src_dict)
        chat = Chat.from_dict(d.pop("chat"))

        definition = ChatDefinition.from_dict(d.pop("definition"))

        chat_detail = cls(
            chat=chat,
            definition=definition,
        )

        chat_detail.additional_properties = d
        return chat_detail

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
