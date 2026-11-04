from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.chat import Chat
    from ..models.chat_participant import ChatParticipant


T = TypeVar("T", bound="ChatParticipantRemoveResult")


@_attrs_define
class ChatParticipantRemoveResult:
    """
    Attributes:
        chat (Chat):
        removed (ChatParticipant):
        new_owner (ChatParticipant | None): The user who became owner when the owner left; otherwise null
    """

    chat: Chat
    removed: ChatParticipant
    new_owner: ChatParticipant | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.chat_participant import ChatParticipant

        chat = self.chat.to_dict()

        removed = self.removed.to_dict()

        new_owner: dict[str, Any] | None
        if isinstance(self.new_owner, ChatParticipant):
            new_owner = self.new_owner.to_dict()
        else:
            new_owner = self.new_owner

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat": chat,
                "removed": removed,
                "newOwner": new_owner,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat import Chat
        from ..models.chat_participant import ChatParticipant

        d = dict(src_dict)
        chat = Chat.from_dict(d.pop("chat"))

        removed = ChatParticipant.from_dict(d.pop("removed"))

        def _parse_new_owner(data: object) -> ChatParticipant | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                new_owner_type_0 = ChatParticipant.from_dict(data)

                return new_owner_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(ChatParticipant | None, data)

        new_owner = _parse_new_owner(d.pop("newOwner"))

        chat_participant_remove_result = cls(
            chat=chat,
            removed=removed,
            new_owner=new_owner,
        )

        chat_participant_remove_result.additional_properties = d
        return chat_participant_remove_result

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
