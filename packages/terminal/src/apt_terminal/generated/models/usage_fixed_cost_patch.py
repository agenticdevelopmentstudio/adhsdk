from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="UsageFixedCostPatch")


@_attrs_define
class UsageFixedCostPatch:
    """
    Attributes:
        label (str | Unset):
        monthly_micros (int | Unset):
        effective_from (datetime.date | Unset):
        effective_to (datetime.date | None | Unset):
        note (str | Unset):
    """

    label: str | Unset = UNSET
    monthly_micros: int | Unset = UNSET
    effective_from: datetime.date | Unset = UNSET
    effective_to: datetime.date | None | Unset = UNSET
    note: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        monthly_micros = self.monthly_micros

        effective_from: str | Unset = UNSET
        if not isinstance(self.effective_from, Unset):
            effective_from = self.effective_from.isoformat()

        effective_to: None | str | Unset
        if isinstance(self.effective_to, Unset):
            effective_to = UNSET
        elif isinstance(self.effective_to, datetime.date):
            effective_to = self.effective_to.isoformat()
        else:
            effective_to = self.effective_to

        note = self.note

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if label is not UNSET:
            field_dict["label"] = label
        if monthly_micros is not UNSET:
            field_dict["monthly_micros"] = monthly_micros
        if effective_from is not UNSET:
            field_dict["effective_from"] = effective_from
        if effective_to is not UNSET:
            field_dict["effective_to"] = effective_to
        if note is not UNSET:
            field_dict["note"] = note

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        label = d.pop("label", UNSET)

        monthly_micros = d.pop("monthly_micros", UNSET)

        _effective_from = d.pop("effective_from", UNSET)
        effective_from: datetime.date | Unset
        if isinstance(_effective_from, Unset):
            effective_from = UNSET
        else:
            effective_from = datetime.date.fromisoformat(_effective_from)

        def _parse_effective_to(data: object) -> datetime.date | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                effective_to_type_0 = datetime.date.fromisoformat(data)

                return effective_to_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.date | None | Unset, data)

        effective_to = _parse_effective_to(d.pop("effective_to", UNSET))

        note = d.pop("note", UNSET)

        usage_fixed_cost_patch = cls(
            label=label,
            monthly_micros=monthly_micros,
            effective_from=effective_from,
            effective_to=effective_to,
            note=note,
        )

        return usage_fixed_cost_patch
