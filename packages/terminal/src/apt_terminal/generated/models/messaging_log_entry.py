from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.messaging_log_entry_channel import MessagingLogEntryChannel
from ..models.messaging_log_entry_origin import MessagingLogEntryOrigin
from ..models.messaging_log_entry_status import MessagingLogEntryStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="MessagingLogEntry")


@_attrs_define
class MessagingLogEntry:
    """
    Attributes:
        id (str):
        owner_kind (str): Kind of principal that owns the message (the recipient, for a message to a user): 'customer',
            'organization', 'application', 'persona' or 'ecosystem'.
        owner_id (str): Id of the owning principal.
        ecosystem_id (str): Ecosystem (tenant) id
        channel (MessagingLogEntryChannel):
        recipient (str): Resolved destination (email address or phone)
        body (str):
        status (MessagingLogEntryStatus): Send outcome
        origin (MessagingLogEntryOrigin): Sending surface: 'ecosystem' = the per-ecosystem Messaging tool; 'platform' =
            automated/system send (only the admin log shows these)
        created_at (str):
        deleted_at (None | str | Unset):
        subject (None | str | Unset):
        template_id (None | str | Unset):
        provider_id (None | str | Unset): Provider message id (when sent)
        error_message (None | str | Unset):
        sent_by (None | str | Unset): Admin user id who issued the send
    """

    id: str
    owner_kind: str
    owner_id: str
    ecosystem_id: str
    channel: MessagingLogEntryChannel
    recipient: str
    body: str
    status: MessagingLogEntryStatus
    origin: MessagingLogEntryOrigin
    created_at: str
    deleted_at: None | str | Unset = UNSET
    subject: None | str | Unset = UNSET
    template_id: None | str | Unset = UNSET
    provider_id: None | str | Unset = UNSET
    error_message: None | str | Unset = UNSET
    sent_by: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        ecosystem_id = self.ecosystem_id

        channel = self.channel.value

        recipient = self.recipient

        body = self.body

        status = self.status.value

        origin = self.origin.value

        created_at = self.created_at

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        subject: None | str | Unset
        if isinstance(self.subject, Unset):
            subject = UNSET
        else:
            subject = self.subject

        template_id: None | str | Unset
        if isinstance(self.template_id, Unset):
            template_id = UNSET
        else:
            template_id = self.template_id

        provider_id: None | str | Unset
        if isinstance(self.provider_id, Unset):
            provider_id = UNSET
        else:
            provider_id = self.provider_id

        error_message: None | str | Unset
        if isinstance(self.error_message, Unset):
            error_message = UNSET
        else:
            error_message = self.error_message

        sent_by: None | str | Unset
        if isinstance(self.sent_by, Unset):
            sent_by = UNSET
        else:
            sent_by = self.sent_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "ecosystemId": ecosystem_id,
                "channel": channel,
                "recipient": recipient,
                "body": body,
                "status": status,
                "origin": origin,
                "createdAt": created_at,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at
        if subject is not UNSET:
            field_dict["subject"] = subject
        if template_id is not UNSET:
            field_dict["templateId"] = template_id
        if provider_id is not UNSET:
            field_dict["providerId"] = provider_id
        if error_message is not UNSET:
            field_dict["errorMessage"] = error_message
        if sent_by is not UNSET:
            field_dict["sentBy"] = sent_by

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        ecosystem_id = d.pop("ecosystemId")

        channel = MessagingLogEntryChannel(d.pop("channel"))

        recipient = d.pop("recipient")

        body = d.pop("body")

        status = MessagingLogEntryStatus(d.pop("status"))

        origin = MessagingLogEntryOrigin(d.pop("origin"))

        created_at = d.pop("createdAt")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        def _parse_subject(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject = _parse_subject(d.pop("subject", UNSET))

        def _parse_template_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        template_id = _parse_template_id(d.pop("templateId", UNSET))

        def _parse_provider_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        provider_id = _parse_provider_id(d.pop("providerId", UNSET))

        def _parse_error_message(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        error_message = _parse_error_message(d.pop("errorMessage", UNSET))

        def _parse_sent_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        sent_by = _parse_sent_by(d.pop("sentBy", UNSET))

        messaging_log_entry = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            ecosystem_id=ecosystem_id,
            channel=channel,
            recipient=recipient,
            body=body,
            status=status,
            origin=origin,
            created_at=created_at,
            deleted_at=deleted_at,
            subject=subject,
            template_id=template_id,
            provider_id=provider_id,
            error_message=error_message,
            sent_by=sent_by,
        )

        messaging_log_entry.additional_properties = d
        return messaging_log_entry

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
