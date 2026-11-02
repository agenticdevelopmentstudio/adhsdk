from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetBillingSubscriptionTiersResponse200Item")


@_attrs_define
class GetBillingSubscriptionTiersResponse200Item:
    """
    Attributes:
        id (str):
        key (str):
        name (str):
        description (None | str):
        display_order (int):
        is_active (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    key: str
    name: str
    description: None | str
    display_order: int
    is_active: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        key = self.key

        name = self.name

        description: None | str
        description = self.description

        display_order = self.display_order

        is_active = self.is_active

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "key": key,
                "name": name,
                "description": description,
                "displayOrder": display_order,
                "isActive": is_active,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

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

        display_order = d.pop("displayOrder")

        is_active = d.pop("isActive")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        get_billing_subscription_tiers_response_200_item = cls(
            id=id,
            key=key,
            name=name,
            description=description,
            display_order=display_order,
            is_active=is_active,
            created_at=created_at,
            updated_at=updated_at,
        )

        return get_billing_subscription_tiers_response_200_item
