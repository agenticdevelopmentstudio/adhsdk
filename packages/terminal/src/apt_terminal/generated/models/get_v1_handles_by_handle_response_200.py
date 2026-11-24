from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_handles_by_handle_response_200_reason import (
    GetV1HandlesByHandleResponse200Reason,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1HandlesByHandleResponse200")


@_attrs_define
class GetV1HandlesByHandleResponse200:
    """
    Attributes:
        available (bool):
        object_ (Literal['handle'] | Unset):
        reason (GetV1HandlesByHandleResponse200Reason | Unset):
    """

    available: bool
    object_: Literal["handle"] | Unset = UNSET
    reason: GetV1HandlesByHandleResponse200Reason | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        available = self.available

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_
        if reason is not UNSET:
            field_dict["reason"] = reason

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        available = d.pop("available")

        object_ = cast(Literal["handle"] | Unset, d.pop("object", UNSET))
        if object_ != "handle" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'handle', got '{object_}'")

        _reason = d.pop("reason", UNSET)
        reason: GetV1HandlesByHandleResponse200Reason | Unset
        if isinstance(_reason, Unset):
            reason = UNSET
        else:
            reason = GetV1HandlesByHandleResponse200Reason(_reason)

        get_v1_handles_by_handle_response_200 = cls(
            available=available,
            object_=object_,
            reason=reason,
        )

        get_v1_handles_by_handle_response_200.additional_properties = d
        return get_v1_handles_by_handle_response_200

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
