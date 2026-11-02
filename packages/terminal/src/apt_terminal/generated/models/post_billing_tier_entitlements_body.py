from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostBillingTierEntitlementsBody")


@_attrs_define
class PostBillingTierEntitlementsBody:
    """
    Attributes:
        tier_id (str):
        entitlement_key (str):
        value_type (str):
        value (str):
    """

    tier_id: str
    entitlement_key: str
    value_type: str
    value: str

    def to_dict(self) -> dict[str, Any]:
        tier_id = self.tier_id

        entitlement_key = self.entitlement_key

        value_type = self.value_type

        value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
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
        tier_id = d.pop("tierId")

        entitlement_key = d.pop("entitlementKey")

        value_type = d.pop("valueType")

        value = d.pop("value")

        post_billing_tier_entitlements_body = cls(
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
        )

        return post_billing_tier_entitlements_body
