from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="BillingAccount")


@_attrs_define
class BillingAccount:
    """
    Attributes:
        id (str):
        offer_id (str):
        status (str):
        created (int): Unix timestamp, in seconds.
        stripe_customer_id (None | str | Unset):
        stripe_checkout_session_id (None | str | Unset):
        stripe_subscription_id (None | str | Unset):
        payer_email (None | str | Unset):
        current_period_end (None | str | Unset):
        lapsed_at (None | str | Unset):
        claimed_customer_id (None | str | Unset):
        claimed_at (None | str | Unset):
    """

    id: str
    offer_id: str
    status: str
    created: int
    stripe_customer_id: None | str | Unset = UNSET
    stripe_checkout_session_id: None | str | Unset = UNSET
    stripe_subscription_id: None | str | Unset = UNSET
    payer_email: None | str | Unset = UNSET
    current_period_end: None | str | Unset = UNSET
    lapsed_at: None | str | Unset = UNSET
    claimed_customer_id: None | str | Unset = UNSET
    claimed_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        offer_id = self.offer_id

        status = self.status

        created = self.created

        stripe_customer_id: None | str | Unset
        if isinstance(self.stripe_customer_id, Unset):
            stripe_customer_id = UNSET
        else:
            stripe_customer_id = self.stripe_customer_id

        stripe_checkout_session_id: None | str | Unset
        if isinstance(self.stripe_checkout_session_id, Unset):
            stripe_checkout_session_id = UNSET
        else:
            stripe_checkout_session_id = self.stripe_checkout_session_id

        stripe_subscription_id: None | str | Unset
        if isinstance(self.stripe_subscription_id, Unset):
            stripe_subscription_id = UNSET
        else:
            stripe_subscription_id = self.stripe_subscription_id

        payer_email: None | str | Unset
        if isinstance(self.payer_email, Unset):
            payer_email = UNSET
        else:
            payer_email = self.payer_email

        current_period_end: None | str | Unset
        if isinstance(self.current_period_end, Unset):
            current_period_end = UNSET
        else:
            current_period_end = self.current_period_end

        lapsed_at: None | str | Unset
        if isinstance(self.lapsed_at, Unset):
            lapsed_at = UNSET
        else:
            lapsed_at = self.lapsed_at

        claimed_customer_id: None | str | Unset
        if isinstance(self.claimed_customer_id, Unset):
            claimed_customer_id = UNSET
        else:
            claimed_customer_id = self.claimed_customer_id

        claimed_at: None | str | Unset
        if isinstance(self.claimed_at, Unset):
            claimed_at = UNSET
        else:
            claimed_at = self.claimed_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "offer_id": offer_id,
                "status": status,
                "created": created,
            }
        )
        if stripe_customer_id is not UNSET:
            field_dict["stripe_customer_id"] = stripe_customer_id
        if stripe_checkout_session_id is not UNSET:
            field_dict["stripe_checkout_session_id"] = stripe_checkout_session_id
        if stripe_subscription_id is not UNSET:
            field_dict["stripe_subscription_id"] = stripe_subscription_id
        if payer_email is not UNSET:
            field_dict["payer_email"] = payer_email
        if current_period_end is not UNSET:
            field_dict["current_period_end"] = current_period_end
        if lapsed_at is not UNSET:
            field_dict["lapsed_at"] = lapsed_at
        if claimed_customer_id is not UNSET:
            field_dict["claimed_customer_id"] = claimed_customer_id
        if claimed_at is not UNSET:
            field_dict["claimed_at"] = claimed_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        offer_id = d.pop("offer_id")

        status = d.pop("status")

        created = d.pop("created")

        def _parse_stripe_customer_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stripe_customer_id = _parse_stripe_customer_id(d.pop("stripe_customer_id", UNSET))

        def _parse_stripe_checkout_session_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stripe_checkout_session_id = _parse_stripe_checkout_session_id(
            d.pop("stripe_checkout_session_id", UNSET)
        )

        def _parse_stripe_subscription_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stripe_subscription_id = _parse_stripe_subscription_id(
            d.pop("stripe_subscription_id", UNSET)
        )

        def _parse_payer_email(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        payer_email = _parse_payer_email(d.pop("payer_email", UNSET))

        def _parse_current_period_end(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        current_period_end = _parse_current_period_end(d.pop("current_period_end", UNSET))

        def _parse_lapsed_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        lapsed_at = _parse_lapsed_at(d.pop("lapsed_at", UNSET))

        def _parse_claimed_customer_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        claimed_customer_id = _parse_claimed_customer_id(d.pop("claimed_customer_id", UNSET))

        def _parse_claimed_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        claimed_at = _parse_claimed_at(d.pop("claimed_at", UNSET))

        billing_account = cls(
            id=id,
            offer_id=offer_id,
            status=status,
            created=created,
            stripe_customer_id=stripe_customer_id,
            stripe_checkout_session_id=stripe_checkout_session_id,
            stripe_subscription_id=stripe_subscription_id,
            payer_email=payer_email,
            current_period_end=current_period_end,
            lapsed_at=lapsed_at,
            claimed_customer_id=claimed_customer_id,
            claimed_at=claimed_at,
        )

        billing_account.additional_properties = d
        return billing_account

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
