from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="InvitationRequest")


@_attrs_define
class InvitationRequest:
    """An unsolicited ask to join, as captured by the public request form.

    Attributes:
        id (str):
        ecosystem_id (str):
        pending_user_id (str):
        name (str):
        email (None | str):
        phone (None | str):
        source (None | str):
        note (None | str):
        created_at (str):
        user_number (int | None):
    """

    id: str
    ecosystem_id: str
    pending_user_id: str
    name: str
    email: None | str
    phone: None | str
    source: None | str
    note: None | str
    created_at: str
    user_number: int | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        pending_user_id = self.pending_user_id

        name = self.name

        email: None | str
        email = self.email

        phone: None | str
        phone = self.phone

        source: None | str
        source = self.source

        note: None | str
        note = self.note

        created_at = self.created_at

        user_number: int | None
        user_number = self.user_number

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "pendingUserId": pending_user_id,
                "name": name,
                "email": email,
                "phone": phone,
                "source": source,
                "note": note,
                "createdAt": created_at,
                "userNumber": user_number,
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

        def _parse_source(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        source = _parse_source(d.pop("source"))

        def _parse_note(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        note = _parse_note(d.pop("note"))

        created_at = d.pop("createdAt")

        def _parse_user_number(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        user_number = _parse_user_number(d.pop("userNumber"))

        invitation_request = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            pending_user_id=pending_user_id,
            name=name,
            email=email,
            phone=phone,
            source=source,
            note=note,
            created_at=created_at,
            user_number=user_number,
        )

        invitation_request.additional_properties = d
        return invitation_request

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
