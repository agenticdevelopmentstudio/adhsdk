from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.set_effective_effective_type_0_error import SetEffectiveEffectiveType0Error
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.set_effective_effective_type_0_limits import SetEffectiveEffectiveType0Limits


T = TypeVar("T", bound="SetEffectiveEffectiveType0")


@_attrs_define
class SetEffectiveEffectiveType0:
    """The customer's answer before the ecosystem's ceiling: null when the ecosystem has no sets; the held set ids,
    features and limits; or { error: 'unresolved' }.

        Attributes:
            held (list[UUID] | Unset):
            permissions (list[str] | Unset):
            read_only (list[str] | Unset):
            limits (SetEffectiveEffectiveType0Limits | Unset):
            valid_until (datetime.datetime | None | Unset): When the answer next changes (a grant lapsing).
            error (SetEffectiveEffectiveType0Error | Unset):
    """

    held: list[UUID] | Unset = UNSET
    permissions: list[str] | Unset = UNSET
    read_only: list[str] | Unset = UNSET
    limits: SetEffectiveEffectiveType0Limits | Unset = UNSET
    valid_until: datetime.datetime | None | Unset = UNSET
    error: SetEffectiveEffectiveType0Error | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        held: list[str] | Unset = UNSET
        if not isinstance(self.held, Unset):
            held = []
            for held_item_data in self.held:
                held_item = str(held_item_data)
                held.append(held_item)

        permissions: list[str] | Unset = UNSET
        if not isinstance(self.permissions, Unset):
            permissions = self.permissions

        read_only: list[str] | Unset = UNSET
        if not isinstance(self.read_only, Unset):
            read_only = self.read_only

        limits: dict[str, Any] | Unset = UNSET
        if not isinstance(self.limits, Unset):
            limits = self.limits.to_dict()

        valid_until: None | str | Unset
        if isinstance(self.valid_until, Unset):
            valid_until = UNSET
        elif isinstance(self.valid_until, datetime.datetime):
            valid_until = self.valid_until.isoformat()
        else:
            valid_until = self.valid_until

        error: str | Unset = UNSET
        if not isinstance(self.error, Unset):
            error = self.error.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if held is not UNSET:
            field_dict["held"] = held
        if permissions is not UNSET:
            field_dict["permissions"] = permissions
        if read_only is not UNSET:
            field_dict["read_only"] = read_only
        if limits is not UNSET:
            field_dict["limits"] = limits
        if valid_until is not UNSET:
            field_dict["valid_until"] = valid_until
        if error is not UNSET:
            field_dict["error"] = error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.set_effective_effective_type_0_limits import (
            SetEffectiveEffectiveType0Limits,
        )

        d = dict(src_dict)
        _held = d.pop("held", UNSET)
        held: list[UUID] | Unset = UNSET
        if _held is not UNSET:
            held = []
            for held_item_data in _held:
                held_item = UUID(held_item_data)

                held.append(held_item)

        permissions = cast(list[str], d.pop("permissions", UNSET))

        read_only = cast(list[str], d.pop("read_only", UNSET))

        _limits = d.pop("limits", UNSET)
        limits: SetEffectiveEffectiveType0Limits | Unset
        if isinstance(_limits, Unset):
            limits = UNSET
        else:
            limits = SetEffectiveEffectiveType0Limits.from_dict(_limits)

        def _parse_valid_until(data: object) -> datetime.datetime | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                valid_until_type_0 = datetime.datetime.fromisoformat(data)

                return valid_until_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None | Unset, data)

        valid_until = _parse_valid_until(d.pop("valid_until", UNSET))

        _error = d.pop("error", UNSET)
        error: SetEffectiveEffectiveType0Error | Unset
        if isinstance(_error, Unset):
            error = UNSET
        else:
            error = SetEffectiveEffectiveType0Error(_error)

        set_effective_effective_type_0 = cls(
            held=held,
            permissions=permissions,
            read_only=read_only,
            limits=limits,
            valid_until=valid_until,
            error=error,
        )

        set_effective_effective_type_0.additional_properties = d
        return set_effective_effective_type_0

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
