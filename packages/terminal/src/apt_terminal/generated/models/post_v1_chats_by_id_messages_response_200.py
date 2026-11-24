from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ChatsByIdMessagesResponse200")


@_attrs_define
class PostV1ChatsByIdMessagesResponse200:
    """
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
        object_ (Literal['message'] | Unset):
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
    object_: Literal["message"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["message"] | Unset, d.pop("object", UNSET))
        if object_ != "message" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'message', got '{object_}'")

        post_v1_chats_by_id_messages_response_200 = cls(
            id=id,
            chat_id=chat_id,
            sender_participant_id=sender_participant_id,
            sender_user_id=sender_user_id,
            seq=seq,
            role=role,
            body=body,
            state=state,
            date_sent=date_sent,
            object_=object_,
        )

        post_v1_chats_by_id_messages_response_200.additional_properties = d
        return post_v1_chats_by_id_messages_response_200

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
