from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingTierEntitlementsByIdBody")


@_attrs_define
class PostV1BillingTierEntitlementsByIdBody:
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
            field_dict["tier_id"] = tier_id
        if entitlement_key is not UNSET:
            field_dict["entitlement_key"] = entitlement_key
        if value_type is not UNSET:
            field_dict["value_type"] = value_type
        if value is not UNSET:
            field_dict["value"] = value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        tier_id = d.pop("tier_id", UNSET)

        entitlement_key = d.pop("entitlement_key", UNSET)

        value_type = d.pop("value_type", UNSET)

        value = d.pop("value", UNSET)

        post_v1_billing_tier_entitlements_by_id_body = cls(
            tier_id=tier_id,
            entitlement_key=entitlement_key,
            value_type=value_type,
            value=value,
        )

        return post_v1_billing_tier_entitlements_by_id_body
