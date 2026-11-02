from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetUsagePrincipalTiersResponse200Item")


@_attrs_define
class GetUsagePrincipalTiersResponse200Item:
    """
    Attributes:
        scope (str):
        principal_id (str):
        tier_id (str):
    """

    scope: str
    principal_id: str
    tier_id: str

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        tier_id = self.tier_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principalId": principal_id,
                "tierId": tier_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principalId")

        tier_id = d.pop("tierId")

        get_usage_principal_tiers_response_200_item = cls(
            scope=scope,
            principal_id=principal_id,
            tier_id=tier_id,
        )

        return get_usage_principal_tiers_response_200_item
