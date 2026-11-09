from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_entry_service_delivery_mode import RegistryEntryServiceDeliveryMode
from ..models.registry_entry_service_pricing_model import RegistryEntryServicePricingModel
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegistryEntriesByIdServicesByServiceIdResponse200")


@_attrs_define
class PostV1RegistryEntriesByIdServicesByServiceIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        entry_id (str):
        title (str):
        description (str):
        pricing_model (RegistryEntryServicePricingModel):
        currency (str):
        unit (str):
        delivery_mode (RegistryEntryServiceDeliveryMode):
        sort_order (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        price_min (int | None | Unset):
        price_max (int | None | Unset):
        deleted_at (None | str | Unset):
        object_ (Literal['service'] | Unset):
    """

    id: str
    ecosystem_id: str
    entry_id: str
    title: str
    description: str
    pricing_model: RegistryEntryServicePricingModel
    currency: str
    unit: str
    delivery_mode: RegistryEntryServiceDeliveryMode
    sort_order: int
    created: int
    updated: int
    sync_version: int
    price_min: int | None | Unset = UNSET
    price_max: int | None | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    object_: Literal["service"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        entry_id = self.entry_id

        title = self.title

        description = self.description

        pricing_model = self.pricing_model.value

        currency = self.currency

        unit = self.unit

        delivery_mode = self.delivery_mode.value

        sort_order = self.sort_order

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        price_min: int | None | Unset
        if isinstance(self.price_min, Unset):
            price_min = UNSET
        else:
            price_min = self.price_min

        price_max: int | None | Unset
        if isinstance(self.price_max, Unset):
            price_max = UNSET
        else:
            price_max = self.price_max

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "entry_id": entry_id,
                "title": title,
                "description": description,
                "pricing_model": pricing_model,
                "currency": currency,
                "unit": unit,
                "delivery_mode": delivery_mode,
                "sort_order": sort_order,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
            }
        )
        if price_min is not UNSET:
            field_dict["price_min"] = price_min
        if price_max is not UNSET:
            field_dict["price_max"] = price_max
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        entry_id = d.pop("entry_id")

        title = d.pop("title")

        description = d.pop("description")

        pricing_model = RegistryEntryServicePricingModel(d.pop("pricing_model"))

        currency = d.pop("currency")

        unit = d.pop("unit")

        delivery_mode = RegistryEntryServiceDeliveryMode(d.pop("delivery_mode"))

        sort_order = d.pop("sort_order")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_price_min(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        price_min = _parse_price_min(d.pop("price_min", UNSET))

        def _parse_price_max(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        price_max = _parse_price_max(d.pop("price_max", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["service"] | Unset, d.pop("object", UNSET))
        if object_ != "service" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'service', got '{object_}'")

        post_v1_registry_entries_by_id_services_by_service_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            entry_id=entry_id,
            title=title,
            description=description,
            pricing_model=pricing_model,
            currency=currency,
            unit=unit,
            delivery_mode=delivery_mode,
            sort_order=sort_order,
            created=created,
            updated=updated,
            sync_version=sync_version,
            price_min=price_min,
            price_max=price_max,
            deleted_at=deleted_at,
            object_=object_,
        )

        post_v1_registry_entries_by_id_services_by_service_id_response_200.additional_properties = d
        return post_v1_registry_entries_by_id_services_by_service_id_response_200

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
