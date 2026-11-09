from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.dm_message import DmMessage


T = TypeVar("T", bound="ChatPersonaReplyEvent")


@_attrs_define
class ChatPersonaReplyEvent:
    """The `data` of an event on the persona-reply stream of POST /chat/chats/{id}/messages. The SSE event name
    discriminates (see the route): `open` carries `message`; `persona_start` carries `participantId` and `personaId`;
    `message` carries `participantId` and `message`; every turn event (`token`, `tool_call_started`,
    `tool_call_completed`, `status`, `award`, `done`, `ended`, `error`) carries its own fields (see ChatStreamEvent)
    plus `participantId`.

        Attributes:
            participant_id (str | Unset): The replying persona’s participant row id
            persona_id (str | Unset): `persona_start`
            message (DmMessage | Unset): One direct message. Also the payload of a `message` event on the DM SSE stream.
    """

    participant_id: str | Unset = UNSET
    persona_id: str | Unset = UNSET
    message: DmMessage | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        participant_id = self.participant_id

        persona_id = self.persona_id

        message: dict[str, Any] | Unset = UNSET
        if not isinstance(self.message, Unset):
            message = self.message.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if participant_id is not UNSET:
            field_dict["participant_id"] = participant_id
        if persona_id is not UNSET:
            field_dict["persona_id"] = persona_id
        if message is not UNSET:
            field_dict["message"] = message

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.dm_message import DmMessage

        d = dict(src_dict)
        participant_id = d.pop("participant_id", UNSET)

        persona_id = d.pop("persona_id", UNSET)

        _message = d.pop("message", UNSET)
        message: DmMessage | Unset
        if isinstance(_message, Unset):
            message = UNSET
        else:
            message = DmMessage.from_dict(_message)

        chat_persona_reply_event = cls(
            participant_id=participant_id,
            persona_id=persona_id,
            message=message,
        )

        chat_persona_reply_event.additional_properties = d
        return chat_persona_reply_event

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
