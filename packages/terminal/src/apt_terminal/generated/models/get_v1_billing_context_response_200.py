from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.billing_context_stripe_status import BillingContextStripeStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1BillingContextResponse200")


@_attrs_define
class GetV1BillingContextResponse200:
    """
    Attributes:
        ecosystem_id (str):
        billing_enabled (bool):
        can_manage (bool):
        stripe_status (BillingContextStripeStatus):
        webhook_path (str):
        object_ (Literal['billing.context'] | Unset):
    """

    ecosystem_id: str
    billing_enabled: bool
    can_manage: bool
    stripe_status: BillingContextStripeStatus
    webhook_path: str
    object_: Literal["billing.context"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        billing_enabled = self.billing_enabled

        can_manage = self.can_manage

        stripe_status = self.stripe_status.value

        webhook_path = self.webhook_path

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem_id": ecosystem_id,
                "billing_enabled": billing_enabled,
                "can_manage": can_manage,
                "stripe_status": stripe_status,
                "webhook_path": webhook_path,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id")

        billing_enabled = d.pop("billing_enabled")

        can_manage = d.pop("can_manage")

        stripe_status = BillingContextStripeStatus(d.pop("stripe_status"))

        webhook_path = d.pop("webhook_path")

        object_ = cast(Literal["billing.context"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.context" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.context', got '{object_}'")

        get_v1_billing_context_response_200 = cls(
            ecosystem_id=ecosystem_id,
            billing_enabled=billing_enabled,
            can_manage=can_manage,
            stripe_status=stripe_status,
            webhook_path=webhook_path,
            object_=object_,
        )

        get_v1_billing_context_response_200.additional_properties = d
        return get_v1_billing_context_response_200

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
