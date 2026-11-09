from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageFixedCost")


@_attrs_define
class UsageFixedCost:
    """
    Attributes:
        id (UUID):
        provider (str):
        label (str):
        monthly_micros (int): µUSD a month, prorated by day
        effective_from (datetime.date):
        effective_to (datetime.date | None): Last day it charges (inclusive); null ⇒ still in effect
        note (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: UUID
    provider: str
    label: str
    monthly_micros: int
    effective_from: datetime.date
    effective_to: datetime.date | None
    note: str
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        provider = self.provider

        label = self.label

        monthly_micros = self.monthly_micros

        effective_from = self.effective_from.isoformat()

        effective_to: None | str
        if isinstance(self.effective_to, datetime.date):
            effective_to = self.effective_to.isoformat()
        else:
            effective_to = self.effective_to

        note = self.note

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "provider": provider,
                "label": label,
                "monthly_micros": monthly_micros,
                "effective_from": effective_from,
                "effective_to": effective_to,
                "note": note,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        provider = d.pop("provider")

        label = d.pop("label")

        monthly_micros = d.pop("monthly_micros")

        effective_from = datetime.date.fromisoformat(d.pop("effective_from"))

        def _parse_effective_to(data: object) -> datetime.date | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                effective_to_type_0 = datetime.date.fromisoformat(data)

                return effective_to_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.date | None, data)

        effective_to = _parse_effective_to(d.pop("effective_to"))

        note = d.pop("note")

        created = d.pop("created")

        updated = d.pop("updated")

        usage_fixed_cost = cls(
            id=id,
            provider=provider,
            label=label,
            monthly_micros=monthly_micros,
            effective_from=effective_from,
            effective_to=effective_to,
            note=note,
            created=created,
            updated=updated,
        )

        usage_fixed_cost.additional_properties = d
        return usage_fixed_cost

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
