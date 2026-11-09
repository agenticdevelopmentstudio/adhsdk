from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingSubscriptionTiersByIdResponse200")


@_attrs_define
class PostV1BillingSubscriptionTiersByIdResponse200:
    """
    Attributes:
        id (str):
        key (str):
        name (str):
        description (None | str):
        display_order (int):
        is_active (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['billing.subscription_tier'] | Unset):
    """

    id: str
    key: str
    name: str
    description: None | str
    display_order: int
    is_active: bool
    created: int
    updated: int
    object_: Literal["billing.subscription_tier"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        key = self.key

        name = self.name

        description: None | str
        description = self.description

        display_order = self.display_order

        is_active = self.is_active

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "key": key,
                "name": name,
                "description": description,
                "display_order": display_order,
                "is_active": is_active,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        key = d.pop("key")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        display_order = d.pop("display_order")

        is_active = d.pop("is_active")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["billing.subscription_tier"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.subscription_tier" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'billing.subscription_tier', got '{object_}'"
            )

        post_v1_billing_subscription_tiers_by_id_response_200 = cls(
            id=id,
            key=key,
            name=name,
            description=description,
            display_order=display_order,
            is_active=is_active,
            created=created,
            updated=updated,
            object_=object_,
        )

        return post_v1_billing_subscription_tiers_by_id_response_200
