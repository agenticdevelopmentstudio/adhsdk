from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PublicInvitationRequest")


@_attrs_define
class PublicInvitationRequest:
    """
    Attributes:
        name (str):
        email (str | Unset):
        phone (str | Unset):
        source (str | Unset):
        note (str | Unset):
        ecosystem (str | Unset): Target ecosystem address (rdid or uuid). Absent = the hub. Unknown/deleted → 404.
    """

    name: str
    email: str | Unset = UNSET
    phone: str | Unset = UNSET
    source: str | Unset = UNSET
    note: str | Unset = UNSET
    ecosystem: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        email = self.email

        phone = self.phone

        source = self.source

        note = self.note

        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if email is not UNSET:
            field_dict["email"] = email
        if phone is not UNSET:
            field_dict["phone"] = phone
        if source is not UNSET:
            field_dict["source"] = source
        if note is not UNSET:
            field_dict["note"] = note
        if ecosystem is not UNSET:
            field_dict["ecosystem"] = ecosystem

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        email = d.pop("email", UNSET)

        phone = d.pop("phone", UNSET)

        source = d.pop("source", UNSET)

        note = d.pop("note", UNSET)

        ecosystem = d.pop("ecosystem", UNSET)

        public_invitation_request = cls(
            name=name,
            email=email,
            phone=phone,
            source=source,
            note=note,
            ecosystem=ecosystem,
        )

        public_invitation_request.additional_properties = d
        return public_invitation_request

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
