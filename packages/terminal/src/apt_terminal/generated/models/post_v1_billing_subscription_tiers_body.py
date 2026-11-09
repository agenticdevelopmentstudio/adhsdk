from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1BillingSubscriptionTiersBody")


@_attrs_define
class PostV1BillingSubscriptionTiersBody:
    """
    Attributes:
        key (str):
        name (str):
        description (None | str | Unset):
        display_order (int | Unset):
        is_active (bool | Unset):
    """

    key: str
    name: str
    description: None | str | Unset = UNSET
    display_order: int | Unset = UNSET
    is_active: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        display_order = self.display_order

        is_active = self.is_active

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "key": key,
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if display_order is not UNSET:
            field_dict["display_order"] = display_order
        if is_active is not UNSET:
            field_dict["is_active"] = is_active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        display_order = d.pop("display_order", UNSET)

        is_active = d.pop("is_active", UNSET)

        post_v1_billing_subscription_tiers_body = cls(
            key=key,
            name=name,
            description=description,
            display_order=display_order,
            is_active=is_active,
        )

        return post_v1_billing_subscription_tiers_body
