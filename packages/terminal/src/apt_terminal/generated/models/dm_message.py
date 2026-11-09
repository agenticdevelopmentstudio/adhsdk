from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="DmMessage")


@_attrs_define
class DmMessage:
    """One direct message. Also the payload of a `message` event on the DM SSE stream.

    Attributes:
        id (str):
        chat_id (str):
        sender_participant_id (None | str):
        sender_user_id (str):
        seq (int): Per-chat monotonic sequence; the stream cursor
        role (str):
        body (str):
        state (str):
        date_sent (str):
    """

    id: str
    chat_id: str
    sender_participant_id: None | str
    sender_user_id: str
    seq: int
    role: str
    body: str
    state: str
    date_sent: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        chat_id = self.chat_id

        sender_participant_id: None | str
        sender_participant_id = self.sender_participant_id

        sender_user_id = self.sender_user_id

        seq = self.seq

        role = self.role

        body = self.body

        state = self.state

        date_sent = self.date_sent

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "chat_id": chat_id,
                "sender_participant_id": sender_participant_id,
                "sender_user_id": sender_user_id,
                "seq": seq,
                "role": role,
                "body": body,
                "state": state,
                "date_sent": date_sent,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        chat_id = d.pop("chat_id")

        def _parse_sender_participant_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sender_participant_id = _parse_sender_participant_id(d.pop("sender_participant_id"))

        sender_user_id = d.pop("sender_user_id")

        seq = d.pop("seq")

        role = d.pop("role")

        body = d.pop("body")

        state = d.pop("state")

        date_sent = d.pop("date_sent")

        dm_message = cls(
            id=id,
            chat_id=chat_id,
            sender_participant_id=sender_participant_id,
            sender_user_id=sender_user_id,
            seq=seq,
            role=role,
            body=body,
            state=state,
            date_sent=date_sent,
        )

        dm_message.additional_properties = d
        return dm_message

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
