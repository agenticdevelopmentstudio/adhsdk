from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingEventsRedriveResponse200")


@_attrs_define
class PostV1BillingEventsRedriveResponse200:
    """
    Attributes:
        examined (int):
        applied (int):
        terminal (int):
        still_pending (int):
        unreadable (int):
        failed (int):
        next_offset (int | None):
        object_ (Literal['billing.event'] | Unset):
    """

    examined: int
    applied: int
    terminal: int
    still_pending: int
    unreadable: int
    failed: int
    next_offset: int | None
    object_: Literal["billing.event"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        examined = self.examined

        applied = self.applied

        terminal = self.terminal

        still_pending = self.still_pending

        unreadable = self.unreadable

        failed = self.failed

        next_offset: int | None
        next_offset = self.next_offset

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "examined": examined,
                "applied": applied,
                "terminal": terminal,
                "still_pending": still_pending,
                "unreadable": unreadable,
                "failed": failed,
                "next_offset": next_offset,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        examined = d.pop("examined")

        applied = d.pop("applied")

        terminal = d.pop("terminal")

        still_pending = d.pop("still_pending")

        unreadable = d.pop("unreadable")

        failed = d.pop("failed")

        def _parse_next_offset(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        next_offset = _parse_next_offset(d.pop("next_offset"))

        object_ = cast(Literal["billing.event"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.event', got '{object_}'")

        post_v1_billing_events_redrive_response_200 = cls(
            examined=examined,
            applied=applied,
            terminal=terminal,
            still_pending=still_pending,
            unreadable=unreadable,
            failed=failed,
            next_offset=next_offset,
            object_=object_,
        )

        post_v1_billing_events_redrive_response_200.additional_properties = d
        return post_v1_billing_events_redrive_response_200

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
