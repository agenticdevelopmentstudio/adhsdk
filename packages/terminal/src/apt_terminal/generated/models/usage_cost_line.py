from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_cost_line_category import UsageCostLineCategory
from ..models.usage_cost_line_paid_by import UsageCostLinePaidBy
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_cost_line_quantities import UsageCostLineQuantities
    from ..models.usage_cost_line_unit_prices_type_0 import UsageCostLineUnitPricesType0


T = TypeVar("T", bound="UsageCostLine")


@_attrs_define
class UsageCostLine:
    """
    Attributes:
        id (UUID):
        call_id (UUID):
        occurred_at (str):
        category (UsageCostLineCategory):
        provider (str):
        sku (str):
        quantities (UsageCostLineQuantities): Key-wise sums of the quantities (requests, input_tokens, minutes, …)
        cost_micros (int | None): µUSD; null ⇒ unpriced
        paid_by (UsageCostLinePaidBy):
        partial (bool): The provider call did not complete; a floor
        attempt (int):
        ecosystem_id (None | Unset | UUID):
        unit_prices (None | Unset | UsageCostLineUnitPricesType0): The per-unit prices the cost was computed from,
            snapshotted
    """

    id: UUID
    call_id: UUID
    occurred_at: str
    category: UsageCostLineCategory
    provider: str
    sku: str
    quantities: UsageCostLineQuantities
    cost_micros: int | None
    paid_by: UsageCostLinePaidBy
    partial: bool
    attempt: int
    ecosystem_id: None | Unset | UUID = UNSET
    unit_prices: None | Unset | UsageCostLineUnitPricesType0 = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.usage_cost_line_unit_prices_type_0 import UsageCostLineUnitPricesType0

        id = str(self.id)

        call_id = str(self.call_id)

        occurred_at = self.occurred_at

        category = self.category.value

        provider = self.provider

        sku = self.sku

        quantities = self.quantities.to_dict()

        cost_micros: int | None
        cost_micros = self.cost_micros

        paid_by = self.paid_by.value

        partial = self.partial

        attempt = self.attempt

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        elif isinstance(self.ecosystem_id, UUID):
            ecosystem_id = str(self.ecosystem_id)
        else:
            ecosystem_id = self.ecosystem_id

        unit_prices: dict[str, Any] | None | Unset
        if isinstance(self.unit_prices, Unset):
            unit_prices = UNSET
        elif isinstance(self.unit_prices, UsageCostLineUnitPricesType0):
            unit_prices = self.unit_prices.to_dict()
        else:
            unit_prices = self.unit_prices

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "call_id": call_id,
                "occurred_at": occurred_at,
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantities": quantities,
                "cost_micros": cost_micros,
                "paid_by": paid_by,
                "partial": partial,
                "attempt": attempt,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if unit_prices is not UNSET:
            field_dict["unit_prices"] = unit_prices

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_cost_line_quantities import UsageCostLineQuantities
        from ..models.usage_cost_line_unit_prices_type_0 import (
            UsageCostLineUnitPricesType0,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        call_id = UUID(d.pop("call_id"))

        occurred_at = d.pop("occurred_at")

        category = UsageCostLineCategory(d.pop("category"))

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantities = UsageCostLineQuantities.from_dict(d.pop("quantities"))

        def _parse_cost_micros(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        cost_micros = _parse_cost_micros(d.pop("cost_micros"))

        paid_by = UsageCostLinePaidBy(d.pop("paid_by"))

        partial = d.pop("partial")

        attempt = d.pop("attempt")

        def _parse_ecosystem_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                ecosystem_id_type_0 = UUID(data)

                return ecosystem_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id", UNSET))

        def _parse_unit_prices(data: object) -> None | Unset | UsageCostLineUnitPricesType0:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                unit_prices_type_0 = UsageCostLineUnitPricesType0.from_dict(data)

                return unit_prices_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UsageCostLineUnitPricesType0, data)

        unit_prices = _parse_unit_prices(d.pop("unit_prices", UNSET))

        usage_cost_line = cls(
            id=id,
            call_id=call_id,
            occurred_at=occurred_at,
            category=category,
            provider=provider,
            sku=sku,
            quantities=quantities,
            cost_micros=cost_micros,
            paid_by=paid_by,
            partial=partial,
            attempt=attempt,
            ecosystem_id=ecosystem_id,
            unit_prices=unit_prices,
        )

        usage_cost_line.additional_properties = d
        return usage_cost_line

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
