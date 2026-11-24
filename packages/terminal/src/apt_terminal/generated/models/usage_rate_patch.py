from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="UsageRatePatch")


@_attrs_define
class UsageRatePatch:
    """
    Attributes:
        micros_per_unit (str | Unset): Exact decimal text, ≥ 0: at most 12 fractional digits and 18 integer digits
            (trailing fractional zeros do not count; exponent form such as `1e-3` is read exactly). Returned in plain form.
        effective_from (datetime.date | Unset):
        note (str | Unset):
    """

    micros_per_unit: str | Unset = UNSET
    effective_from: datetime.date | Unset = UNSET
    note: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        micros_per_unit = self.micros_per_unit

        effective_from: str | Unset = UNSET
        if not isinstance(self.effective_from, Unset):
            effective_from = self.effective_from.isoformat()

        note = self.note

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if micros_per_unit is not UNSET:
            field_dict["micros_per_unit"] = micros_per_unit
        if effective_from is not UNSET:
            field_dict["effective_from"] = effective_from
        if note is not UNSET:
            field_dict["note"] = note

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        micros_per_unit = d.pop("micros_per_unit", UNSET)

        _effective_from = d.pop("effective_from", UNSET)
        effective_from: datetime.date | Unset
        if isinstance(_effective_from, Unset):
            effective_from = UNSET
        else:
            effective_from = datetime.date.fromisoformat(_effective_from)

        note = d.pop("note", UNSET)

        usage_rate_patch = cls(
            micros_per_unit=micros_per_unit,
            effective_from=effective_from,
            note=note,
        )

        return usage_rate_patch
