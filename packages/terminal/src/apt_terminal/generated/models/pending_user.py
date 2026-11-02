from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.pending_user_status import PendingUserStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PendingUser")


@_attrs_define
class PendingUser:
    """A person known to the ecosystem who has not accepted an invitation yet.

    Attributes:
        id (str):
        ecosystem_id (str):
        user_number (int): Sequential within the ecosystem, assigned on insert
        name (str):
        email (None | str):
        phone (None | str):
        status (PendingUserStatus):
        request_count (int):
        invited_count (int):
        last_request_at (None | str):
        last_invite_sent_at (None | str):
        first_requested_at (str):
        last_source (None | str):
        last_note (None | str):
        accepted_customer_id (None | str):
        created_at (str):
        updated_at (str):
        contact_id (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    user_number: int
    name: str
    email: None | str
    phone: None | str
    status: PendingUserStatus
    request_count: int
    invited_count: int
    last_request_at: None | str
    last_invite_sent_at: None | str
    first_requested_at: str
    last_source: None | str
    last_note: None | str
    accepted_customer_id: None | str
    created_at: str
    updated_at: str
    contact_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        user_number = self.user_number

        name = self.name

        email: None | str
        email = self.email

        phone: None | str
        phone = self.phone

        status = self.status.value

        request_count = self.request_count

        invited_count = self.invited_count

        last_request_at: None | str
        last_request_at = self.last_request_at

        last_invite_sent_at: None | str
        last_invite_sent_at = self.last_invite_sent_at

        first_requested_at = self.first_requested_at

        last_source: None | str
        last_source = self.last_source

        last_note: None | str
        last_note = self.last_note

        accepted_customer_id: None | str
        accepted_customer_id = self.accepted_customer_id

        created_at = self.created_at

        updated_at = self.updated_at

        contact_id: None | str | Unset
        if isinstance(self.contact_id, Unset):
            contact_id = UNSET
        else:
            contact_id = self.contact_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "userNumber": user_number,
                "name": name,
                "email": email,
                "phone": phone,
                "status": status,
                "requestCount": request_count,
                "invitedCount": invited_count,
                "lastRequestAt": last_request_at,
                "lastInviteSentAt": last_invite_sent_at,
                "firstRequestedAt": first_requested_at,
                "lastSource": last_source,
                "lastNote": last_note,
                "acceptedCustomerId": accepted_customer_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if contact_id is not UNSET:
            field_dict["contactId"] = contact_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        user_number = d.pop("userNumber")

        name = d.pop("name")

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        def _parse_phone(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        phone = _parse_phone(d.pop("phone"))

        status = PendingUserStatus(d.pop("status"))

        request_count = d.pop("requestCount")

        invited_count = d.pop("invitedCount")

        def _parse_last_request_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_request_at = _parse_last_request_at(d.pop("lastRequestAt"))

        def _parse_last_invite_sent_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_invite_sent_at = _parse_last_invite_sent_at(d.pop("lastInviteSentAt"))

        first_requested_at = d.pop("firstRequestedAt")

        def _parse_last_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_source = _parse_last_source(d.pop("lastSource"))

        def _parse_last_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_note = _parse_last_note(d.pop("lastNote"))

        def _parse_accepted_customer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        accepted_customer_id = _parse_accepted_customer_id(d.pop("acceptedCustomerId"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_contact_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        contact_id = _parse_contact_id(d.pop("contactId", UNSET))

        pending_user = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            user_number=user_number,
            name=name,
            email=email,
            phone=phone,
            status=status,
            request_count=request_count,
            invited_count=invited_count,
            last_request_at=last_request_at,
            last_invite_sent_at=last_invite_sent_at,
            first_requested_at=first_requested_at,
            last_source=last_source,
            last_note=last_note,
            accepted_customer_id=accepted_customer_id,
            created_at=created_at,
            updated_at=updated_at,
            contact_id=contact_id,
        )

        pending_user.additional_properties = d
        return pending_user

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
