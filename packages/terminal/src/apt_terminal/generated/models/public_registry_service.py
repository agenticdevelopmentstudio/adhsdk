from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_registry_service_delivery_mode import PublicRegistryServiceDeliveryMode
from ..models.public_registry_service_pricing_model import PublicRegistryServicePricingModel

T = TypeVar("T", bound="PublicRegistryService")


@_attrs_define
class PublicRegistryService:
    """
    Attributes:
        title (str):
        description (str):
        pricing_model (PublicRegistryServicePricingModel):
        price_min (int | None):
        price_max (int | None):
        currency (str):
        unit (str):
        delivery_mode (PublicRegistryServiceDeliveryMode):
    """

    title: str
    description: str
    pricing_model: PublicRegistryServicePricingModel
    price_min: int | None
    price_max: int | None
    currency: str
    unit: str
    delivery_mode: PublicRegistryServiceDeliveryMode
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description = self.description

        pricing_model = self.pricing_model.value

        price_min: int | None
        price_min = self.price_min

        price_max: int | None
        price_max = self.price_max

        currency = self.currency

        unit = self.unit

        delivery_mode = self.delivery_mode.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "title": title,
                "description": description,
                "pricingModel": pricing_model,
                "priceMin": price_min,
                "priceMax": price_max,
                "currency": currency,
                "unit": unit,
                "deliveryMode": delivery_mode,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title")

        description = d.pop("description")

        pricing_model = PublicRegistryServicePricingModel(d.pop("pricingModel"))

        def _parse_price_min(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        price_min = _parse_price_min(d.pop("priceMin"))

        def _parse_price_max(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        price_max = _parse_price_max(d.pop("priceMax"))

        currency = d.pop("currency")

        unit = d.pop("unit")

        delivery_mode = PublicRegistryServiceDeliveryMode(d.pop("deliveryMode"))

        public_registry_service = cls(
            title=title,
            description=description,
            pricing_model=pricing_model,
            price_min=price_min,
            price_max=price_max,
            currency=currency,
            unit=unit,
            delivery_mode=delivery_mode,
        )

        public_registry_service.additional_properties = d
        return public_registry_service

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
