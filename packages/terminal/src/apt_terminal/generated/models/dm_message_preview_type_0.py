from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="DmMessagePreviewType0")


@_attrs_define
class DmMessagePreviewType0:
    """The chat's most recent message, trimmed to what a chat list renders.

    Attributes:
        id (str):
        sender_participant_id (None | str):
        body (str):
        seq (int):
        date_sent (str):
    """

    id: str
    sender_participant_id: None | str
    body: str
    seq: int
    date_sent: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        sender_participant_id: None | str
        sender_participant_id = self.sender_participant_id

        body = self.body

        seq = self.seq

        date_sent = self.date_sent

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "senderParticipantId": sender_participant_id,
                "body": body,
                "seq": seq,
                "dateSent": date_sent,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        def _parse_sender_participant_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sender_participant_id = _parse_sender_participant_id(d.pop("senderParticipantId"))

        body = d.pop("body")

        seq = d.pop("seq")

        date_sent = d.pop("dateSent")

        dm_message_preview_type_0 = cls(
            id=id,
            sender_participant_id=sender_participant_id,
            body=body,
            seq=seq,
            date_sent=date_sent,
        )

        dm_message_preview_type_0.additional_properties = d
        return dm_message_preview_type_0

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
