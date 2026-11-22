from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="SignupListEntry")


@_attrs_define
class SignupListEntry:
    """
    Attributes:
        id (UUID):
        email (str): Trimmed and lower-cased
        role_id (None | UUID): The role granted at the first proven session; null grants none
        set_id (None | UUID): Reserved for sets; always null for now
        created (int): Unix timestamp, in seconds.
        granted_at (datetime.datetime | None): When the entry was applied; null while it waits
        granted_customer_id (None | str):
    """

    id: UUID
    email: str
    role_id: None | UUID
    set_id: None | UUID
    created: int
    granted_at: datetime.datetime | None
    granted_customer_id: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        email = self.email

        role_id: None | str
        if isinstance(self.role_id, UUID):
            role_id = str(self.role_id)
        else:
            role_id = self.role_id

        set_id: None | str
        if isinstance(self.set_id, UUID):
            set_id = str(self.set_id)
        else:
            set_id = self.set_id

        created = self.created

        granted_at: None | str
        if isinstance(self.granted_at, datetime.datetime):
            granted_at = self.granted_at.isoformat()
        else:
            granted_at = self.granted_at

        granted_customer_id: None | str
        granted_customer_id = self.granted_customer_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "email": email,
                "role_id": role_id,
                "set_id": set_id,
                "created": created,
                "granted_at": granted_at,
                "granted_customer_id": granted_customer_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        email = d.pop("email")

        def _parse_role_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                role_id_type_0 = UUID(data)

                return role_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        role_id = _parse_role_id(d.pop("role_id"))

        def _parse_set_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                set_id_type_0 = UUID(data)

                return set_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        set_id = _parse_set_id(d.pop("set_id"))

        created = d.pop("created")

        def _parse_granted_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                granted_at_type_0 = datetime.datetime.fromisoformat(data)

                return granted_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        granted_at = _parse_granted_at(d.pop("granted_at"))

        def _parse_granted_customer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        granted_customer_id = _parse_granted_customer_id(d.pop("granted_customer_id"))

        signup_list_entry = cls(
            id=id,
            email=email,
            role_id=role_id,
            set_id=set_id,
            created=created,
            granted_at=granted_at,
            granted_customer_id=granted_customer_id,
        )

        signup_list_entry.additional_properties = d
        return signup_list_entry

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
