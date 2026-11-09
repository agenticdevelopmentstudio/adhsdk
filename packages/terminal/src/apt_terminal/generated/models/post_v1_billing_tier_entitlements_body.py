from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostV1BillingTierEntitlementsBody")


@_attrs_define
class PostV1BillingTierEntitlementsBody:
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
                "tier_id": tier_id,
                "entitlement_key": entitlement_key,
                "value_type": value_type,
                "value": value,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tier_id = d.pop("tier_id")

        entitlement_key = d.pop("entitlement_key")

        value_type = d.pop("value_type")

        value = d.pop("value")

        post_v1_billing_tier_entitlements_body = cls(
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
        )

        return post_v1_billing_tier_entitlements_body
