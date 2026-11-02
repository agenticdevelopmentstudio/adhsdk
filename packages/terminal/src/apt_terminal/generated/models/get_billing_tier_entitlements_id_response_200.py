from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetBillingTierEntitlementsIdResponse200")


@_attrs_define
class GetBillingTierEntitlementsIdResponse200:
    """
    Attributes:
        id (str):
        tier_id (str):
        entitlement_key (str):
        value_type (str):
        value (str):
    """

    id: str
    tier_id: str
    entitlement_key: str
    value_type: str
    value: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        tier_id = self.tier_id

        entitlement_key = self.entitlement_key

        value_type = self.value_type

        value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "tierId": tier_id,
                "entitlementKey": entitlement_key,
                "valueType": value_type,
                "value": value,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        tier_id = d.pop("tierId")

        entitlement_key = d.pop("entitlementKey")

        value_type = d.pop("valueType")

        value = d.pop("value")

        get_billing_tier_entitlements_id_response_200 = cls(
            id=id,
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
        )

        return get_billing_tier_entitlements_id_response_200
