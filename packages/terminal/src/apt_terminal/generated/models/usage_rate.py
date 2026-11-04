from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_rate_category import UsageRateCategory

T = TypeVar("T", bound="UsageRate")


@_attrs_define
class UsageRate:
    """
    Attributes:
        id (UUID):
        category (UsageRateCategory):
        provider (str):
        sku (str):
        quantity_key (str): The `quantities` key the rate prices
        micros_per_unit (str): Exact decimal µUSD per unit (numeric text, never a float)
        effective_from (datetime.date):
        note (str):
        created_at (datetime.datetime):
        created_by_user_id (None | UUID):
    """

    id: UUID
    category: UsageRateCategory
    provider: str
    sku: str
    quantity_key: str
    micros_per_unit: str
    effective_from: datetime.date
    note: str
    created_at: datetime.datetime
    created_by_user_id: None | UUID
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        category = self.category.value

        provider = self.provider

        sku = self.sku

        quantity_key = self.quantity_key

        micros_per_unit = self.micros_per_unit

        effective_from = self.effective_from.isoformat()

        note = self.note

        created_at = self.created_at.isoformat()

        created_by_user_id: None | str
        if isinstance(self.created_by_user_id, UUID):
            created_by_user_id = str(self.created_by_user_id)
        else:
            created_by_user_id = self.created_by_user_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantityKey": quantity_key,
                "microsPerUnit": micros_per_unit,
                "effectiveFrom": effective_from,
                "note": note,
                "createdAt": created_at,
                "createdByUserId": created_by_user_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        category = UsageRateCategory(d.pop("category"))

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantity_key = d.pop("quantityKey")

        micros_per_unit = d.pop("microsPerUnit")

        effective_from = datetime.date.fromisoformat(d.pop("effectiveFrom"))

        note = d.pop("note")

        created_at = datetime.datetime.fromisoformat(d.pop("createdAt"))

        def _parse_created_by_user_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                created_by_user_id_type_0 = UUID(data)

                return created_by_user_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        created_by_user_id = _parse_created_by_user_id(d.pop("createdByUserId"))

        usage_rate = cls(
            id=id,
            category=category,
            provider=provider,
            sku=sku,
            quantity_key=quantity_key,
            micros_per_unit=micros_per_unit,
            effective_from=effective_from,
            note=note,
            created_at=created_at,
            created_by_user_id=created_by_user_id,
        )

        usage_rate.additional_properties = d
        return usage_rate

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
