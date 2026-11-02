from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.billing_context_stripe_status import BillingContextStripeStatus

T = TypeVar("T", bound="BillingContext")


@_attrs_define
class BillingContext:
    """
    Attributes:
        ecosystem_id (str):
        billing_enabled (bool):
        can_manage (bool):
        stripe_status (BillingContextStripeStatus):
        webhook_path (str):
    """

    ecosystem_id: str
    billing_enabled: bool
    can_manage: bool
    stripe_status: BillingContextStripeStatus
    webhook_path: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        billing_enabled = self.billing_enabled

        can_manage = self.can_manage

        stripe_status = self.stripe_status.value

        webhook_path = self.webhook_path

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystemId": ecosystem_id,
                "billingEnabled": billing_enabled,
                "canManage": can_manage,
                "stripeStatus": stripe_status,
                "webhookPath": webhook_path,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId")

        billing_enabled = d.pop("billingEnabled")

        can_manage = d.pop("canManage")

        stripe_status = BillingContextStripeStatus(d.pop("stripeStatus"))

        webhook_path = d.pop("webhookPath")

        billing_context = cls(
            ecosystem_id=ecosystem_id,
            billing_enabled=billing_enabled,
            can_manage=can_manage,
            stripe_status=stripe_status,
            webhook_path=webhook_path,
        )

        billing_context.additional_properties = d
        return billing_context

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
