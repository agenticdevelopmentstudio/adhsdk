from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="VisitorTurnRequest")


@_attrs_define
class VisitorTurnRequest:
    """
    Attributes:
        message (str): Over the per-message character ceiling this is a 422, not a 400
        client_message_id (str | Unset):
    """

    message: str
    client_message_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        message = self.message

        client_message_id = self.client_message_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "message": message,
            }
        )
        if client_message_id is not UNSET:
            field_dict["clientMessageId"] = client_message_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        message = d.pop("message")

        client_message_id = d.pop("clientMessageId", UNSET)

        visitor_turn_request = cls(
            message=message,
            client_message_id=client_message_id,
        )

        visitor_turn_request.additional_properties = d
        return visitor_turn_request

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
