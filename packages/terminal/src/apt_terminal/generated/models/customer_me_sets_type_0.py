from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.customer_me_sets_type_0_error import CustomerMeSetsType0Error
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.customer_me_sets_type_0_limits import CustomerMeSetsType0Limits


T = TypeVar("T", bound="CustomerMeSetsType0")


@_attrs_define
class CustomerMeSetsType0:
    """The customer's effective sets in its realm: null when the realm has no sets; the held set ids, the features they
    grant (all or read-only) and their limits; or { error: 'unresolved' } when the answer could not be computed while
    set enforcement is off (with it on, the request is refused 403).

        Attributes:
            held (list[str] | Unset): Held set ids.
            permissions (list[str] | Unset):
            read_only (list[str] | Unset):
            limits (CustomerMeSetsType0Limits | Unset):
            error (CustomerMeSetsType0Error | Unset):
    """

    held: list[str] | Unset = UNSET
    permissions: list[str] | Unset = UNSET
    read_only: list[str] | Unset = UNSET
    limits: CustomerMeSetsType0Limits | Unset = UNSET
    error: CustomerMeSetsType0Error | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        held: list[str] | Unset = UNSET
        if not isinstance(self.held, Unset):
            held = self.held

        permissions: list[str] | Unset = UNSET
        if not isinstance(self.permissions, Unset):
            permissions = self.permissions

        read_only: list[str] | Unset = UNSET
        if not isinstance(self.read_only, Unset):
            read_only = self.read_only

        limits: dict[str, Any] | Unset = UNSET
        if not isinstance(self.limits, Unset):
            limits = self.limits.to_dict()

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
        if error is not UNSET:
            field_dict["error"] = error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.customer_me_sets_type_0_limits import (
            CustomerMeSetsType0Limits,
        )

        d = dict(src_dict)
        held = cast(list[str], d.pop("held", UNSET))

        permissions = cast(list[str], d.pop("permissions", UNSET))

        read_only = cast(list[str], d.pop("read_only", UNSET))

        _limits = d.pop("limits", UNSET)
        limits: CustomerMeSetsType0Limits | Unset
        if isinstance(_limits, Unset):
            limits = UNSET
        else:
            limits = CustomerMeSetsType0Limits.from_dict(_limits)

        _error = d.pop("error", UNSET)
        error: CustomerMeSetsType0Error | Unset
        if isinstance(_error, Unset):
            error = UNSET
        else:
            error = CustomerMeSetsType0Error(_error)

        customer_me_sets_type_0 = cls(
            held=held,
            permissions=permissions,
            read_only=read_only,
            limits=limits,
            error=error,
        )

        customer_me_sets_type_0.additional_properties = d
        return customer_me_sets_type_0

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
