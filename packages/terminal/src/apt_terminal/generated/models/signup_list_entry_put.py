from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="SignupListEntryPut")


@_attrs_define
class SignupListEntryPut:
    """
    Attributes:
        email (str): Stored trimmed and lower-cased
        role_id (None | Unset | UUID):
        set_id (None | Unset | UUID): A set of this ecosystem (422 otherwise); null grants none
    """

    email: str
    role_id: None | Unset | UUID = UNSET
    set_id: None | Unset | UUID = UNSET

    def to_dict(self) -> dict[str, Any]:
        email = self.email

        role_id: None | str | Unset
        if isinstance(self.role_id, Unset):
            role_id = UNSET
        elif isinstance(self.role_id, UUID):
            role_id = str(self.role_id)
        else:
            role_id = self.role_id

        set_id: None | str | Unset
        if isinstance(self.set_id, Unset):
            set_id = UNSET
        elif isinstance(self.set_id, UUID):
            set_id = str(self.set_id)
        else:
            set_id = self.set_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "email": email,
            }
        )
        if role_id is not UNSET:
            field_dict["role_id"] = role_id
        if set_id is not UNSET:
            field_dict["set_id"] = set_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        email = d.pop("email")

        def _parse_role_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                role_id_type_0 = UUID(data)

                return role_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        role_id = _parse_role_id(d.pop("role_id", UNSET))

        def _parse_set_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                set_id_type_0 = UUID(data)

                return set_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        set_id = _parse_set_id(d.pop("set_id", UNSET))

        signup_list_entry_put = cls(
            email=email,
            role_id=role_id,
            set_id=set_id,
        )

        return signup_list_entry_put
