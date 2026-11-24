from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="BillingRedriveResult")


@_attrs_define
class BillingRedriveResult:
    """
    Attributes:
        examined (int):
        applied (int):
        terminal (int):
        still_pending (int):
        unreadable (int):
        failed (int):
        next_offset (int | None):
    """

    examined: int
    applied: int
    terminal: int
    still_pending: int
    unreadable: int
    failed: int
    next_offset: int | None
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

        billing_redrive_result = cls(
            examined=examined,
            applied=applied,
            terminal=terminal,
            still_pending=still_pending,
            unreadable=unreadable,
            failed=failed,
            next_offset=next_offset,
        )

        billing_redrive_result.additional_properties = d
        return billing_redrive_result

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
