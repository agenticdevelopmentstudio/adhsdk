from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_cost_row_category import UsageCostRowCategory
from ..models.usage_cost_row_paid_by import UsageCostRowPaidBy
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_cost_row_quantities import UsageCostRowQuantities


T = TypeVar("T", bound="UsageCostRow")


@_attrs_define
class UsageCostRow:
    """
    Attributes:
        cost_micros (int): Summed cost in µUSD (unpriced lines add 0)
        unpriced_lines (int): Lines with no price; > 0 ⇒ a floor
        lines (int): Cost lines summed into this row
        quantities (UsageCostRowQuantities): Key-wise sums of the quantities (requests, input_tokens, minutes, …)
        day (datetime.date | Unset): groupBy=day only
        ecosystem_key (UUID | Unset): groupBy=key only. The nil uuid is platform-level spend
        category (UsageCostRowCategory | Unset): groupBy=key only
        provider (str | Unset): groupBy=key only
        sku (str | Unset): groupBy=key only
        paid_by (UsageCostRowPaidBy | Unset): groupBy=key only
    """

    cost_micros: int
    unpriced_lines: int
    lines: int
    quantities: UsageCostRowQuantities
    day: datetime.date | Unset = UNSET
    ecosystem_key: UUID | Unset = UNSET
    category: UsageCostRowCategory | Unset = UNSET
    provider: str | Unset = UNSET
    sku: str | Unset = UNSET
    paid_by: UsageCostRowPaidBy | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        cost_micros = self.cost_micros

        unpriced_lines = self.unpriced_lines

        lines = self.lines

        quantities = self.quantities.to_dict()

        day: str | Unset = UNSET
        if not isinstance(self.day, Unset):
            day = self.day.isoformat()

        ecosystem_key: str | Unset = UNSET
        if not isinstance(self.ecosystem_key, Unset):
            ecosystem_key = str(self.ecosystem_key)

        category: str | Unset = UNSET
        if not isinstance(self.category, Unset):
            category = self.category.value

        provider = self.provider

        sku = self.sku

        paid_by: str | Unset = UNSET
        if not isinstance(self.paid_by, Unset):
            paid_by = self.paid_by.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "cost_micros": cost_micros,
                "unpriced_lines": unpriced_lines,
                "lines": lines,
                "quantities": quantities,
            }
        )
        if day is not UNSET:
            field_dict["day"] = day
        if ecosystem_key is not UNSET:
            field_dict["ecosystem_key"] = ecosystem_key
        if category is not UNSET:
            field_dict["category"] = category
        if provider is not UNSET:
            field_dict["provider"] = provider
        if sku is not UNSET:
            field_dict["sku"] = sku
        if paid_by is not UNSET:
            field_dict["paid_by"] = paid_by

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_cost_row_quantities import UsageCostRowQuantities

        d = dict(src_dict)
        cost_micros = d.pop("cost_micros")

        unpriced_lines = d.pop("unpriced_lines")

        lines = d.pop("lines")

        quantities = UsageCostRowQuantities.from_dict(d.pop("quantities"))

        _day = d.pop("day", UNSET)
        day: datetime.date | Unset
        if isinstance(_day, Unset):
            day = UNSET
        else:
            day = datetime.date.fromisoformat(_day)

        _ecosystem_key = d.pop("ecosystem_key", UNSET)
        ecosystem_key: UUID | Unset
        if isinstance(_ecosystem_key, Unset):
            ecosystem_key = UNSET
        else:
            ecosystem_key = UUID(_ecosystem_key)

        _category = d.pop("category", UNSET)
        category: UsageCostRowCategory | Unset
        if isinstance(_category, Unset):
            category = UNSET
        else:
            category = UsageCostRowCategory(_category)

        provider = d.pop("provider", UNSET)

        sku = d.pop("sku", UNSET)

        _paid_by = d.pop("paid_by", UNSET)
        paid_by: UsageCostRowPaidBy | Unset
        if isinstance(_paid_by, Unset):
            paid_by = UNSET
        else:
            paid_by = UsageCostRowPaidBy(_paid_by)

        usage_cost_row = cls(
            cost_micros=cost_micros,
            unpriced_lines=unpriced_lines,
            lines=lines,
            quantities=quantities,
            day=day,
            ecosystem_key=ecosystem_key,
            category=category,
            provider=provider,
            sku=sku,
            paid_by=paid_by,
        )

        usage_cost_row.additional_properties = d
        return usage_cost_row

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
