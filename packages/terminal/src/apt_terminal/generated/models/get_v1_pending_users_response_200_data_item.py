from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.pending_user_status import PendingUserStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1PendingUsersResponse200DataItem")


@_attrs_define
class GetV1PendingUsersResponse200DataItem:
    """
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        contact_id (None | str | Unset):
        object_ (Literal['pending_user'] | Unset):
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
    created: int
    updated: int
    contact_id: None | str | Unset = UNSET
    object_: Literal["pending_user"] | Unset = UNSET
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

        created = self.created

        updated = self.updated

        contact_id: None | str | Unset
        if isinstance(self.contact_id, Unset):
            contact_id = UNSET
        else:
            contact_id = self.contact_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "user_number": user_number,
                "name": name,
                "email": email,
                "phone": phone,
                "status": status,
                "request_count": request_count,
                "invited_count": invited_count,
                "last_request_at": last_request_at,
                "last_invite_sent_at": last_invite_sent_at,
                "first_requested_at": first_requested_at,
                "last_source": last_source,
                "last_note": last_note,
                "accepted_customer_id": accepted_customer_id,
                "created": created,
                "updated": updated,
            }
        )
        if contact_id is not UNSET:
            field_dict["contact_id"] = contact_id
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        user_number = d.pop("user_number")

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

        request_count = d.pop("request_count")

        invited_count = d.pop("invited_count")

        def _parse_last_request_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_request_at = _parse_last_request_at(d.pop("last_request_at"))

        def _parse_last_invite_sent_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_invite_sent_at = _parse_last_invite_sent_at(d.pop("last_invite_sent_at"))

        first_requested_at = d.pop("first_requested_at")

        def _parse_last_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_source = _parse_last_source(d.pop("last_source"))

        def _parse_last_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_note = _parse_last_note(d.pop("last_note"))

        def _parse_accepted_customer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        accepted_customer_id = _parse_accepted_customer_id(d.pop("accepted_customer_id"))

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_contact_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        contact_id = _parse_contact_id(d.pop("contact_id", UNSET))

        object_ = cast(Literal["pending_user"] | Unset, d.pop("object", UNSET))
        if object_ != "pending_user" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'pending_user', got '{object_}'")

        get_v1_pending_users_response_200_data_item = cls(
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
            created=created,
            updated=updated,
            contact_id=contact_id,
            object_=object_,
        )

        get_v1_pending_users_response_200_data_item.additional_properties = d
        return get_v1_pending_users_response_200_data_item

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
