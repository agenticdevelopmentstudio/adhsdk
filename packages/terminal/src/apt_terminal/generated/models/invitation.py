from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.invitation_channel import InvitationChannel
from ..models.invitation_status import InvitationStatus

T = TypeVar("T", bound="Invitation")


@_attrs_define
class Invitation:
    """One invite delivered to one destination. Inviting by both email and SMS makes two.

    Attributes:
        id (str):
        ecosystem_id (str):
        pending_user_id (str):
        name (str):
        channel (InvitationChannel):
        destination (str):
        token_hash (str):
        status (InvitationStatus):
        sent_by (str):
        sent_at (str):
        expires_at (str):
        accepted_at (None | str):
        accepted_customer_id (None | str):
        message_log_id (None | str):
        admin_note (None | str):
        created_at (str):
    """

    id: str
    ecosystem_id: str
    pending_user_id: str
    name: str
    channel: InvitationChannel
    destination: str
    token_hash: str
    status: InvitationStatus
    sent_by: str
    sent_at: str
    expires_at: str
    accepted_at: None | str
    accepted_customer_id: None | str
    message_log_id: None | str
    admin_note: None | str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        pending_user_id = self.pending_user_id

        name = self.name

        channel = self.channel.value

        destination = self.destination

        token_hash = self.token_hash

        status = self.status.value

        sent_by = self.sent_by

        sent_at = self.sent_at

        expires_at = self.expires_at

        accepted_at: None | str
        accepted_at = self.accepted_at

        accepted_customer_id: None | str
        accepted_customer_id = self.accepted_customer_id

        message_log_id: None | str
        message_log_id = self.message_log_id

        admin_note: None | str
        admin_note = self.admin_note

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "pendingUserId": pending_user_id,
                "name": name,
                "channel": channel,
                "destination": destination,
                "tokenHash": token_hash,
                "status": status,
                "sentBy": sent_by,
                "sentAt": sent_at,
                "expiresAt": expires_at,
                "acceptedAt": accepted_at,
                "acceptedCustomerId": accepted_customer_id,
                "messageLogId": message_log_id,
                "adminNote": admin_note,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        pending_user_id = d.pop("pendingUserId")

        name = d.pop("name")

        channel = InvitationChannel(d.pop("channel"))

        destination = d.pop("destination")

        token_hash = d.pop("tokenHash")

        status = InvitationStatus(d.pop("status"))

        sent_by = d.pop("sentBy")

        sent_at = d.pop("sentAt")

        expires_at = d.pop("expiresAt")

        def _parse_accepted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        accepted_at = _parse_accepted_at(d.pop("acceptedAt"))

        def _parse_accepted_customer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        accepted_customer_id = _parse_accepted_customer_id(d.pop("acceptedCustomerId"))

        def _parse_message_log_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        message_log_id = _parse_message_log_id(d.pop("messageLogId"))

        def _parse_admin_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        admin_note = _parse_admin_note(d.pop("adminNote"))

        created_at = d.pop("createdAt")

        invitation = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            pending_user_id=pending_user_id,
            name=name,
            channel=channel,
            destination=destination,
            token_hash=token_hash,
            status=status,
            sent_by=sent_by,
            sent_at=sent_at,
            expires_at=expires_at,
            accepted_at=accepted_at,
            accepted_customer_id=accepted_customer_id,
            message_log_id=message_log_id,
            admin_note=admin_note,
            created_at=created_at,
        )

        invitation.additional_properties = d
        return invitation

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
