from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.chat_participant_type import ChatParticipantType

T = TypeVar("T", bound="ChatParticipant")


@_attrs_define
class ChatParticipant:
    """
    Attributes:
        id (str): The participant ROW id — what a message’s `senderParticipantId` names
        participant_id (str): A user id or a persona id, per `type`
        type_ (ChatParticipantType):
        role (str): owner, member or assistant
        joined_at (str):
    """

    id: str
    participant_id: str
    type_: ChatParticipantType
    role: str
    joined_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        participant_id = self.participant_id

        type_ = self.type_.value

        role = self.role

        joined_at = self.joined_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "participant_id": participant_id,
                "type": type_,
                "role": role,
                "joined_at": joined_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        participant_id = d.pop("participant_id")

        type_ = ChatParticipantType(d.pop("type"))

        role = d.pop("role")

        joined_at = d.pop("joined_at")

        chat_participant = cls(
            id=id,
            participant_id=participant_id,
            type_=type_,
            role=role,
            joined_at=joined_at,
        )

        chat_participant.additional_properties = d
        return chat_participant

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
