from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_auth_slug_available_slug_response_200_reason import (
    GetAuthSlugAvailableSlugResponse200Reason,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetAuthSlugAvailableSlugResponse200")


@_attrs_define
class GetAuthSlugAvailableSlugResponse200:
    """
    Attributes:
        available (bool):
        reason (GetAuthSlugAvailableSlugResponse200Reason | Unset):
    """

    available: bool
    reason: GetAuthSlugAvailableSlugResponse200Reason | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        available = self.available

        reason: str | Unset = UNSET
        if not isinstance(self.reason, Unset):
            reason = self.reason.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "available": available,
            }
        )
        if reason is not UNSET:
            field_dict["reason"] = reason

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        available = d.pop("available")

        _reason = d.pop("reason", UNSET)
        reason: GetAuthSlugAvailableSlugResponse200Reason | Unset
        if isinstance(_reason, Unset):
            reason = UNSET
        else:
            reason = GetAuthSlugAvailableSlugResponse200Reason(_reason)

        get_auth_slug_available_slug_response_200 = cls(
            available=available,
            reason=reason,
        )

        get_auth_slug_available_slug_response_200.additional_properties = d
        return get_auth_slug_available_slug_response_200

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
