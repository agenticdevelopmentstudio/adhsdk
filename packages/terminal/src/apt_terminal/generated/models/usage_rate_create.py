from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..models.usage_rate_create_category import UsageRateCreateCategory
from ..types import UNSET, Unset

T = TypeVar("T", bound="UsageRateCreate")


@_attrs_define
class UsageRateCreate:
    """
    Attributes:
        category (UsageRateCreateCategory):
        provider (str):
        sku (str):
        quantity_key (str):
        micros_per_unit (str): Exact decimal text, ≥ 0: at most 12 fractional digits and 18 integer digits (trailing
            fractional zeros do not count; exponent form such as `1e-3` is read exactly). Returned in plain form.
        effective_from (datetime.date | Unset): Default: today (UTC)
        note (str | Unset):
    """

    category: UsageRateCreateCategory
    provider: str
    sku: str
    quantity_key: str
    micros_per_unit: str
    effective_from: datetime.date | Unset = UNSET
    note: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        category = self.category.value

        provider = self.provider

        sku = self.sku

        quantity_key = self.quantity_key

        micros_per_unit = self.micros_per_unit

        effective_from: str | Unset = UNSET
        if not isinstance(self.effective_from, Unset):
            effective_from = self.effective_from.isoformat()

        note = self.note

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantityKey": quantity_key,
                "microsPerUnit": micros_per_unit,
            }
        )
        if effective_from is not UNSET:
            field_dict["effectiveFrom"] = effective_from
        if note is not UNSET:
            field_dict["note"] = note

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        category = UsageRateCreateCategory(d.pop("category"))

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantity_key = d.pop("quantityKey")

        micros_per_unit = d.pop("microsPerUnit")

        _effective_from = d.pop("effectiveFrom", UNSET)
        effective_from: datetime.date | Unset
        if isinstance(_effective_from, Unset):
            effective_from = UNSET
        else:
            effective_from = datetime.date.fromisoformat(_effective_from)

        note = d.pop("note", UNSET)

        usage_rate_create = cls(
            category=category,
            provider=provider,
            sku=sku,
            quantity_key=quantity_key,
            micros_per_unit=micros_per_unit,
            effective_from=effective_from,
            note=note,
        )

        return usage_rate_create
