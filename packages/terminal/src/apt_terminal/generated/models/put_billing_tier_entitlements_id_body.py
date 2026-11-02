from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutBillingTierEntitlementsIdBody")


@_attrs_define
class PutBillingTierEntitlementsIdBody:
    """
    Attributes:
        tier_id (str | Unset):
        entitlement_key (str | Unset):
        value_type (str | Unset):
        value (str | Unset):
    """

    tier_id: str | Unset = UNSET
    entitlement_key: str | Unset = UNSET
    value_type: str | Unset = UNSET
    value: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        tier_id = self.tier_id

        entitlement_key = self.entitlement_key

        value_type = self.value_type

        value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if tier_id is not UNSET:
            field_dict["tierId"] = tier_id
        if entitlement_key is not UNSET:
            field_dict["entitlementKey"] = entitlement_key
        if value_type is not UNSET:
            field_dict["valueType"] = value_type
        if value is not UNSET:
            field_dict["value"] = value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tier_id = d.pop("tierId", UNSET)

        entitlement_key = d.pop("entitlementKey", UNSET)

        value_type = d.pop("valueType", UNSET)

        value = d.pop("value", UNSET)

        put_billing_tier_entitlements_id_body = cls(
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
        )

        return put_billing_tier_entitlements_id_body
