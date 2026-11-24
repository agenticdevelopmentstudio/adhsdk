from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="BillingPriceOption")


@_attrs_define
class BillingPriceOption:
    """
    Attributes:
        id (str):
        product_id (str):
        currency (str):
        product_name (None | str | Unset):
        unit_amount (int | None | Unset):
        interval (None | str | Unset):
    """

    id: str
    product_id: str
    currency: str
    product_name: None | str | Unset = UNSET
    unit_amount: int | None | Unset = UNSET
    interval: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        product_id = self.product_id

        currency = self.currency

        product_name: None | str | Unset
        if isinstance(self.product_name, Unset):
            product_name = UNSET
        else:
            product_name = self.product_name

        unit_amount: int | None | Unset
        if isinstance(self.unit_amount, Unset):
            unit_amount = UNSET
        else:
            unit_amount = self.unit_amount

        interval: None | str | Unset
        if isinstance(self.interval, Unset):
            interval = UNSET
        else:
            interval = self.interval

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "product_id": product_id,
                "currency": currency,
            }
        )
        if product_name is not UNSET:
            field_dict["product_name"] = product_name
        if unit_amount is not UNSET:
            field_dict["unit_amount"] = unit_amount
        if interval is not UNSET:
            field_dict["interval"] = interval

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        product_id = d.pop("product_id")

        currency = d.pop("currency")

        def _parse_product_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        product_name = _parse_product_name(d.pop("product_name", UNSET))

        def _parse_unit_amount(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        unit_amount = _parse_unit_amount(d.pop("unit_amount", UNSET))

        def _parse_interval(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        interval = _parse_interval(d.pop("interval", UNSET))

        billing_price_option = cls(
            id=id,
            product_id=product_id,
            currency=currency,
            product_name=product_name,
            unit_amount=unit_amount,
            interval=interval,
        )

        billing_price_option.additional_properties = d
        return billing_price_option

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
