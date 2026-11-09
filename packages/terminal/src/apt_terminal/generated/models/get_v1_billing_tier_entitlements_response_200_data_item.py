from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1BillingTierEntitlementsResponse200DataItem")


@_attrs_define
class GetV1BillingTierEntitlementsResponse200DataItem:
    """
    Attributes:
        id (str):
        tier_id (str):
        entitlement_key (str):
        value_type (str):
        value (str):
        object_ (Literal['billing.tier_entitlement'] | Unset):
    """

    id: str
    tier_id: str
    entitlement_key: str
    value_type: str
    value: str
    object_: Literal["billing.tier_entitlement"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        tier_id = self.tier_id

        entitlement_key = self.entitlement_key

        value_type = self.value_type

        value = self.value

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "tier_id": tier_id,
                "entitlement_key": entitlement_key,
                "value_type": value_type,
                "value": value,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        tier_id = d.pop("tier_id")

        entitlement_key = d.pop("entitlement_key")

        value_type = d.pop("value_type")

        value = d.pop("value")

        object_ = cast(Literal["billing.tier_entitlement"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.tier_entitlement" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.tier_entitlement', got '{object_}'")

        get_v1_billing_tier_entitlements_response_200_data_item = cls(
            id=id,
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
            object_=object_,
        )

        return get_v1_billing_tier_entitlements_response_200_data_item
