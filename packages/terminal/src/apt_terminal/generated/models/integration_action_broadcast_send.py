from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationActionBroadcastSend")


@_attrs_define
class IntegrationActionBroadcastSend:
    """actionType=broadcast_send — dispatch a broadcast previously created by actionType=broadcast

    Attributes:
        broadcast_id (str): The externalId returned by the broadcast action
    """

    broadcast_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        broadcast_id = self.broadcast_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "broadcastId": broadcast_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        broadcast_id = d.pop("broadcastId")

        integration_action_broadcast_send = cls(
            broadcast_id=broadcast_id,
        )

        integration_action_broadcast_send.additional_properties = d
        return integration_action_broadcast_send

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
