from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsageFixedCostsResponse200DataItem")


@_attrs_define
class GetV1UsageFixedCostsResponse200DataItem:
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
        object_ (Literal['usage.fixed_cost'] | Unset):
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
    object_: Literal["usage.fixed_cost"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["usage.fixed_cost"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.fixed_cost" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.fixed_cost', got '{object_}'")

        get_v1_usage_fixed_costs_response_200_data_item = cls(
            id=id,
            provider=provider,
            label=label,
            monthly_micros=monthly_micros,
            effective_from=effective_from,
            effective_to=effective_to,
            note=note,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_usage_fixed_costs_response_200_data_item.additional_properties = d
        return get_v1_usage_fixed_costs_response_200_data_item

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
