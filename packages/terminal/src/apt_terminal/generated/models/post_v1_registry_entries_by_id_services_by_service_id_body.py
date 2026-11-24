from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_registry_entries_by_id_services_by_service_id_body_delivery_mode import (
    PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode,
)
from ..models.post_v1_registry_entries_by_id_services_by_service_id_body_pricing_model import (
    PostV1RegistryEntriesByIdServicesByServiceIdBodyPricingModel,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1RegistryEntriesByIdServicesByServiceIdBody")


@_attrs_define
class PostV1RegistryEntriesByIdServicesByServiceIdBody:
    """
    Attributes:
        registry (str): Scopes the call; the caller passes it as a parameter, not in the path.
        title (str | Unset):
        description (str | Unset):
        pricing_model (PostV1RegistryEntriesByIdServicesByServiceIdBodyPricingModel | Unset):
        price_min (int | None | Unset):
        price_max (int | None | Unset):
        currency (str | Unset):
        unit (str | Unset):
        delivery_mode (PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode | Unset):
        sort_order (int | Unset):
    """

    registry: str
    title: str | Unset = UNSET
    description: str | Unset = UNSET
    pricing_model: PostV1RegistryEntriesByIdServicesByServiceIdBodyPricingModel | Unset = UNSET
    price_min: int | None | Unset = UNSET
    price_max: int | None | Unset = UNSET
    currency: str | Unset = UNSET
    unit: str | Unset = UNSET
    delivery_mode: PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode | Unset = UNSET
    sort_order: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        registry = self.registry

        title = self.title

        description = self.description

        pricing_model: str | Unset = UNSET
        if not isinstance(self.pricing_model, Unset):
            pricing_model = self.pricing_model.value

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

        currency = self.currency

        unit = self.unit

        delivery_mode: str | Unset = UNSET
        if not isinstance(self.delivery_mode, Unset):
            delivery_mode = self.delivery_mode.value

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "registry": registry,
            }
        )
        if title is not UNSET:
            field_dict["title"] = title
        if description is not UNSET:
            field_dict["description"] = description
        if pricing_model is not UNSET:
            field_dict["pricing_model"] = pricing_model
        if price_min is not UNSET:
            field_dict["price_min"] = price_min
        if price_max is not UNSET:
            field_dict["price_max"] = price_max
        if currency is not UNSET:
            field_dict["currency"] = currency
        if unit is not UNSET:
            field_dict["unit"] = unit
        if delivery_mode is not UNSET:
            field_dict["delivery_mode"] = delivery_mode
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        registry = d.pop("registry")

        title = d.pop("title", UNSET)

        description = d.pop("description", UNSET)

        _pricing_model = d.pop("pricing_model", UNSET)
        pricing_model: PostV1RegistryEntriesByIdServicesByServiceIdBodyPricingModel | Unset
        if isinstance(_pricing_model, Unset):
            pricing_model = UNSET
        else:
            pricing_model = PostV1RegistryEntriesByIdServicesByServiceIdBodyPricingModel(
                _pricing_model
            )

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

        currency = d.pop("currency", UNSET)

        unit = d.pop("unit", UNSET)

        _delivery_mode = d.pop("delivery_mode", UNSET)
        delivery_mode: PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode | Unset
        if isinstance(_delivery_mode, Unset):
            delivery_mode = UNSET
        else:
            delivery_mode = PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode(
                _delivery_mode
            )

        sort_order = d.pop("sort_order", UNSET)

        post_v1_registry_entries_by_id_services_by_service_id_body = cls(
            registry=registry,
            title=title,
            description=description,
            pricing_model=pricing_model,
            price_min=price_min,
            price_max=price_max,
            currency=currency,
            unit=unit,
            delivery_mode=delivery_mode,
            sort_order=sort_order,
        )

        post_v1_registry_entries_by_id_services_by_service_id_body.additional_properties = d
        return post_v1_registry_entries_by_id_services_by_service_id_body

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
