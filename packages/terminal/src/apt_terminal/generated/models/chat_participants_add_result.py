from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.chat import Chat
    from ..models.chat_participant import ChatParticipant


T = TypeVar("T", bound="ChatParticipantsAddResult")


@_attrs_define
class ChatParticipantsAddResult:
    """
    Attributes:
        chat (Chat):
        added (list[ChatParticipant]):
        skipped_persona_ids (list[str]): The definition’s own personas that were asked for but not seated because they
            no longer exist
    """

    chat: Chat
    added: list[ChatParticipant]
    skipped_persona_ids: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chat = self.chat.to_dict()

        added = []
        for added_item_data in self.added:
            added_item = added_item_data.to_dict()
            added.append(added_item)

        skipped_persona_ids = self.skipped_persona_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chat": chat,
                "added": added,
                "skippedPersonaIds": skipped_persona_ids,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat import Chat
        from ..models.chat_participant import ChatParticipant

        d = dict(src_dict)
        chat = Chat.from_dict(d.pop("chat"))

        added = []
        _added = d.pop("added")
        for added_item_data in _added:
            added_item = ChatParticipant.from_dict(added_item_data)

            added.append(added_item)

        skipped_persona_ids = cast(list[str], d.pop("skippedPersonaIds"))

        chat_participants_add_result = cls(
            chat=chat,
            added=added,
            skipped_persona_ids=skipped_persona_ids,
        )

        chat_participants_add_result.additional_properties = d
        return chat_participants_add_result

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
