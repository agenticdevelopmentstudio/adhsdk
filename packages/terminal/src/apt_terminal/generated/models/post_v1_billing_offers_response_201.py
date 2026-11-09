from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingOffersResponse201")


@_attrs_define
class PostV1BillingOffersResponse201:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        object_ (Literal['billing.offer'] | Unset):
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
    created: int
    updated: int
    deleted_at: None | str
    object_: Literal["billing.offer"] | Unset = UNSET

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

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "purpose": purpose,
                "stripe_price_id": stripe_price_id,
                "stripe_product_id": stripe_product_id,
                "collection_method": collection_method,
                "days_until_due": days_until_due,
                "grants_ecosystem_id": grants_ecosystem_id,
                "lapse_action": lapse_action,
                "grace_days": grace_days,
                "is_active": is_active,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        purpose = d.pop("purpose")

        stripe_price_id = d.pop("stripe_price_id")

        def _parse_stripe_product_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        stripe_product_id = _parse_stripe_product_id(d.pop("stripe_product_id"))

        collection_method = d.pop("collection_method")

        def _parse_days_until_due(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        days_until_due = _parse_days_until_due(d.pop("days_until_due"))

        def _parse_grants_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        grants_ecosystem_id = _parse_grants_ecosystem_id(d.pop("grants_ecosystem_id"))

        lapse_action = d.pop("lapse_action")

        grace_days = d.pop("grace_days")

        is_active = d.pop("is_active")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        object_ = cast(Literal["billing.offer"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.offer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.offer', got '{object_}'")

        post_v1_billing_offers_response_201 = cls(
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
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            object_=object_,
        )

        return post_v1_billing_offers_response_201
