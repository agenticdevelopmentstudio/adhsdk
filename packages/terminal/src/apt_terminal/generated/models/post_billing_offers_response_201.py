from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostBillingOffersResponse201")


@_attrs_define
class PostBillingOffersResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        slug (str):
        name (str):
        description (None | str):
        purpose (str):
        stripe_price_id (str):
        stripe_product_id (None | str):
        collection_method (str):
        days_until_due (int | None):
        grants_ecosystem_id (None | str):
        lapse_action (str):
        grace_days (int):
        is_active (bool):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    slug: str
    name: str
    description: None | str
    purpose: str
    stripe_price_id: str
    stripe_product_id: None | str
    collection_method: str
    days_until_due: int | None
    grants_ecosystem_id: None | str
    lapse_action: str
    grace_days: int
    is_active: bool
    created_at: str
    updated_at: str
    deleted_at: None | str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        slug = self.slug

        name = self.name

        description: None | str
        description = self.description

        purpose = self.purpose

        stripe_price_id = self.stripe_price_id

        stripe_product_id: None | str
        stripe_product_id = self.stripe_product_id

        collection_method = self.collection_method

        days_until_due: int | None
        days_until_due = self.days_until_due

        grants_ecosystem_id: None | str
        grants_ecosystem_id = self.grants_ecosystem_id

        lapse_action = self.lapse_action

        grace_days = self.grace_days

        is_active = self.is_active

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str
        deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "purpose": purpose,
                "stripePriceId": stripe_price_id,
                "stripeProductId": stripe_product_id,
                "collectionMethod": collection_method,
                "daysUntilDue": days_until_due,
                "grantsEcosystemId": grants_ecosystem_id,
                "lapseAction": lapse_action,
                "graceDays": grace_days,
                "isActive": is_active,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        purpose = d.pop("purpose")

        stripe_price_id = d.pop("stripePriceId")

        def _parse_stripe_product_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        stripe_product_id = _parse_stripe_product_id(d.pop("stripeProductId"))

        collection_method = d.pop("collectionMethod")

        def _parse_days_until_due(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        days_until_due = _parse_days_until_due(d.pop("daysUntilDue"))

        def _parse_grants_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        grants_ecosystem_id = _parse_grants_ecosystem_id(d.pop("grantsEcosystemId"))

        lapse_action = d.pop("lapseAction")

        grace_days = d.pop("graceDays")

        is_active = d.pop("isActive")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        post_billing_offers_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
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
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
        )

        return post_billing_offers_response_201
