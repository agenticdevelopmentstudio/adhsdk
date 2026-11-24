from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_rate_category import UsageRateCategory
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageRatesByIdResponse200")


@_attrs_define
class PostV1UsageRatesByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        created_by_user_id (None | UUID):
        object_ (Literal['usage.rate'] | Unset):
    """

    id: UUID
    category: UsageRateCategory
    provider: str
    sku: str
    quantity_key: str
    micros_per_unit: str
    effective_from: datetime.date
    note: str
    created: int
    created_by_user_id: None | UUID
    object_: Literal["usage.rate"] | Unset = UNSET
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

        created = self.created

        created_by_user_id: None | str
        if isinstance(self.created_by_user_id, UUID):
            created_by_user_id = str(self.created_by_user_id)
        else:
            created_by_user_id = self.created_by_user_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "category": category,
                "provider": provider,
                "sku": sku,
                "quantity_key": quantity_key,
                "micros_per_unit": micros_per_unit,
                "effective_from": effective_from,
                "note": note,
                "created": created,
                "created_by_user_id": created_by_user_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        category = UsageRateCategory(d.pop("category"))

        provider = d.pop("provider")

        sku = d.pop("sku")

        quantity_key = d.pop("quantity_key")

        micros_per_unit = d.pop("micros_per_unit")

        effective_from = datetime.date.fromisoformat(d.pop("effective_from"))

        note = d.pop("note")

        created = d.pop("created")

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

        created_by_user_id = _parse_created_by_user_id(d.pop("created_by_user_id"))

        object_ = cast(Literal["usage.rate"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.rate" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.rate', got '{object_}'")

        post_v1_usage_rates_by_id_response_200 = cls(
            id=id,
            category=category,
            provider=provider,
            sku=sku,
            quantity_key=quantity_key,
            micros_per_unit=micros_per_unit,
            effective_from=effective_from,
            note=note,
            created=created,
            created_by_user_id=created_by_user_id,
            object_=object_,
        )

        post_v1_usage_rates_by_id_response_200.additional_properties = d
        return post_v1_usage_rates_by_id_response_200

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
