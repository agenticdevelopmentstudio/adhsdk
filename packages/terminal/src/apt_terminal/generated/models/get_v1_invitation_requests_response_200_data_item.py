from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1InvitationRequestsResponse200DataItem")


@_attrs_define
class GetV1InvitationRequestsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        pending_user_id (str):
        name (str):
        email (None | str):
        phone (None | str):
        source (None | str):
        note (None | str):
        created (int): Unix timestamp, in seconds.
        user_number (int | None):
        object_ (Literal['invitation_request'] | Unset):
    """

    id: str
    ecosystem_id: str
    pending_user_id: str
    name: str
    email: None | str
    phone: None | str
    source: None | str
    note: None | str
    created: int
    user_number: int | None
    object_: Literal["invitation_request"] | Unset = UNSET
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

        created = self.created

        user_number: int | None
        user_number = self.user_number

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "pending_user_id": pending_user_id,
                "name": name,
                "email": email,
                "phone": phone,
                "source": source,
                "note": note,
                "created": created,
                "user_number": user_number,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        pending_user_id = d.pop("pending_user_id")

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

        created = d.pop("created")

        def _parse_user_number(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        user_number = _parse_user_number(d.pop("user_number"))

        object_ = cast(Literal["invitation_request"] | Unset, d.pop("object", UNSET))
        if object_ != "invitation_request" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'invitation_request', got '{object_}'")

        get_v1_invitation_requests_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            pending_user_id=pending_user_id,
            name=name,
            email=email,
            phone=phone,
            source=source,
            note=note,
            created=created,
            user_number=user_number,
            object_=object_,
        )

        get_v1_invitation_requests_response_200_data_item.additional_properties = d
        return get_v1_invitation_requests_response_200_data_item

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
