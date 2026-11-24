from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingOffersByIdBody")


@_attrs_define
class PostV1BillingOffersByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        slug (str | Unset):
        name (str | Unset):
        description (None | str | Unset):
        purpose (str | Unset):
        stripe_price_id (str | Unset):
        stripe_product_id (None | str | Unset):
        collection_method (str | Unset):
        days_until_due (int | None | Unset):
        grants_ecosystem_id (None | str | Unset):
        lapse_action (str | Unset):
        grace_days (int | Unset):
        is_active (bool | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    purpose: str | Unset = UNSET
    stripe_price_id: str | Unset = UNSET
    stripe_product_id: None | str | Unset = UNSET
    collection_method: str | Unset = UNSET
    days_until_due: int | None | Unset = UNSET
    grants_ecosystem_id: None | str | Unset = UNSET
    lapse_action: str | Unset = UNSET
    grace_days: int | Unset = UNSET
    is_active: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        slug = self.slug

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        purpose = self.purpose

        stripe_price_id = self.stripe_price_id

        stripe_product_id: None | str | Unset
        if isinstance(self.stripe_product_id, Unset):
            stripe_product_id = UNSET
        else:
            stripe_product_id = self.stripe_product_id

        collection_method = self.collection_method

        days_until_due: int | None | Unset
        if isinstance(self.days_until_due, Unset):
            days_until_due = UNSET
        else:
            days_until_due = self.days_until_due

        grants_ecosystem_id: None | str | Unset
        if isinstance(self.grants_ecosystem_id, Unset):
            grants_ecosystem_id = UNSET
        else:
            grants_ecosystem_id = self.grants_ecosystem_id

        lapse_action = self.lapse_action

        grace_days = self.grace_days

        is_active = self.is_active

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if purpose is not UNSET:
            field_dict["purpose"] = purpose
        if stripe_price_id is not UNSET:
            field_dict["stripe_price_id"] = stripe_price_id
        if stripe_product_id is not UNSET:
            field_dict["stripe_product_id"] = stripe_product_id
        if collection_method is not UNSET:
            field_dict["collection_method"] = collection_method
        if days_until_due is not UNSET:
            field_dict["days_until_due"] = days_until_due
        if grants_ecosystem_id is not UNSET:
            field_dict["grants_ecosystem_id"] = grants_ecosystem_id
        if lapse_action is not UNSET:
            field_dict["lapse_action"] = lapse_action
        if grace_days is not UNSET:
            field_dict["grace_days"] = grace_days
        if is_active is not UNSET:
            field_dict["is_active"] = is_active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        purpose = d.pop("purpose", UNSET)

        stripe_price_id = d.pop("stripe_price_id", UNSET)

        def _parse_stripe_product_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        stripe_product_id = _parse_stripe_product_id(d.pop("stripe_product_id", UNSET))

        collection_method = d.pop("collection_method", UNSET)

        def _parse_days_until_due(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        days_until_due = _parse_days_until_due(d.pop("days_until_due", UNSET))

        def _parse_grants_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        grants_ecosystem_id = _parse_grants_ecosystem_id(d.pop("grants_ecosystem_id", UNSET))

        lapse_action = d.pop("lapse_action", UNSET)

        grace_days = d.pop("grace_days", UNSET)

        is_active = d.pop("is_active", UNSET)

        post_v1_billing_offers_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            slug=slug,
            name=name,
            description=description,
            purpose=purpose,
            stripe_price_id=stripe_price_id,
            stripe_product_id=stripe_product_id,
            collection_method=collection_method,
            days_until_due=days_until_due,
            grants_ecosystem_id=grants_ecosystem_id,
            lapse_action=lapse_action,
            grace_days=grace_days,
            is_active=is_active,
        )

        return post_v1_billing_offers_by_id_body
